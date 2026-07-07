import os
import socket
import requests
import psycopg2
from flask import Flask, jsonify, request
from datetime import datetime
import json

app = Flask(__name__)

# ============================================
# HELPER FUNCTIONS
# ============================================

def get_instance_metadata():
    """Fetch AWS instance metadata (AZ, region, instance ID)"""
    try:
        # Try to get metadata from AWS IMDS (Instance Metadata Service)
        response = requests.get(
            'http://169.254.169.254/latest/meta-data/placement/availability-zone',
            timeout=2
        )
        availability_zone = response.text.strip()
        
        response = requests.get(
            'http://169.254.169.254/latest/meta-data/instance-id',
            timeout=2
        )
        instance_id = response.text.strip()
        
        region = availability_zone[:-1]  # Remove last character (e.g., "us-east-1a" -> "us-east-1")
        
        return {
            'availability_zone': availability_zone,
            'region': region,
            'instance_id': instance_id
        }
    except Exception as e:
        # If running locally or metadata unavailable, return fallback
        return {
            'availability_zone': 'unknown',
            'region': 'unknown',
            'instance_id': 'local'
        }

def get_db_connection():
    """Create database connection with timeout"""
    return psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        database=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD'),
        connect_timeout=5,
        port=5432
    )

def check_database():
    """Check database connectivity and return detailed status"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        result = cur.fetchone()
        cur.close()
        conn.close()
        return {
            'status': 'healthy',
            'message': 'Database connection successful',
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
    except psycopg2.OperationalError as e:
        return {
            'status': 'unhealthy',
            'message': f'Database connection failed: {str(e)}',
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
    except Exception as e:
        return {
            'status': 'unhealthy',
            'message': f'Unexpected database error: {str(e)}',
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }

def check_ecs_health():
    """Check ECS container health (simple self-check)"""
    return {
        'status': 'healthy',
        'message': 'Container is running',
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }

# ============================================
# ROUTES
# ============================================

@app.route('/')
def index():
    """Root endpoint - shows basic app info"""
    metadata = get_instance_metadata()
    return jsonify({
        'application': 'AWS DR Simulation App',
        'version': '1.0.0',
        'instance': {
            'availability_zone': metadata['availability_zone'],
            'region': metadata['region'],
            'instance_id': metadata['instance_id'],
            'hostname': socket.gethostname()
        },
        'endpoints': {
            'health': '/health',
            'health_detailed': '/health/detailed',
            'diagnostics': '/diagnostics',
            'info': '/'
        },
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    })

@app.route('/health')
def health():
    """Simple health check for ALB - returns 200 only if DB is healthy"""
    db_status = check_database()
    if db_status['status'] == 'healthy':
        return jsonify({'status': 'healthy'}), 200
    else:
        return jsonify({'status': 'unhealthy'}), 500

@app.route('/health/detailed')
def health_detailed():
    """Detailed health check - returns all component statuses"""
    metadata = get_instance_metadata()
    db_status = check_database()
    ecs_status = check_ecs_health()
    
    # Overall status = unhealthy if any component is unhealthy
    overall_status = 'healthy'
    if db_status['status'] != 'healthy' or ecs_status['status'] != 'healthy':
        overall_status = 'unhealthy'
    
    return jsonify({
        'overall_status': overall_status,
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'instance': {
            'availability_zone': metadata['availability_zone'],
            'region': metadata['region'],
            'instance_id': metadata['instance_id'],
            'hostname': socket.gethostname(),
            'ip_address': request.remote_addr
        },
        'components': {
            'database': db_status,
            'ecs_container': ecs_status
        },
        'environment_variables': {
            'DB_HOST': os.environ.get('DB_HOST', 'not set'),
            'DB_NAME': os.environ.get('DB_NAME', 'not set'),
            'DB_USER': os.environ.get('DB_USER', 'not set'),
            'DB_PASSWORD': '***' if os.environ.get('DB_PASSWORD') else 'not set'
        }
    })

@app.route('/diagnostics')
def diagnostics():
    """Comprehensive diagnostics for debugging"""
    metadata = get_instance_metadata()
    
    # Try to get more metadata if available
    try:
        response = requests.get(
            'http://169.254.169.254/latest/meta-data/local-ipv4',
            timeout=2
        )
        local_ip = response.text.strip()
    except:
        local_ip = 'unknown'
    
    try:
        response = requests.get(
            'http://169.254.169.254/latest/meta-data/public-ipv4',
            timeout=2
        )
        public_ip = response.text.strip()
    except:
        public_ip = 'unknown'
    
    # Environment info
    env_info = {
        'DB_HOST': os.environ.get('DB_HOST', 'not set'),
        'DB_NAME': os.environ.get('DB_NAME', 'not set'),
        'DB_USER': os.environ.get('DB_USER', 'not set'),
        'DB_PASSWORD': '***' if os.environ.get('DB_PASSWORD') else 'not set',
        'AWS_REGION': os.environ.get('AWS_REGION', 'not set'),
        'ECS_CLUSTER': os.environ.get('ECS_CLUSTER', 'not set'),
        'ECS_TASK_DEFINITION': os.environ.get('ECS_TASK_DEFINITION', 'not set'),
    }
    
    # Try database connection
    db_status = check_database()
    
    return jsonify({
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'instance': {
            'availability_zone': metadata['availability_zone'],
            'region': metadata['region'],
            'instance_id': metadata['instance_id'],
            'hostname': socket.gethostname(),
            'local_ip': local_ip,
            'public_ip': public_ip,
            'remote_addr': request.remote_addr
        },
        'environment': env_info,
        'database_connection': db_status,
        'system': {
            'python_version': os.sys.version,
            'platform': os.uname().sysname if hasattr(os, 'uname') else 'unknown'
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)