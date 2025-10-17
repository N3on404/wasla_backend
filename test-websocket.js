#!/usr/bin/env node

const WebSocket = require('ws');

// Get JWT token from auth service
const https = require('https');
const http = require('http');

function getToken() {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({ cin: '12345678' });
        
        const options = {
            hostname: 'localhost',
            port: 8001,
            path: '/api/v1/auth/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(body);
                    resolve(response.data.token);
                } catch (e) {
                    reject(e);
                }
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function testWebSocket() {
    try {
        console.log('🔐 Getting JWT token...');
        const token = await getToken();
        console.log('✅ Token received:', token.substring(0, 50) + '...');

        console.log('🔌 Connecting to WebSocket...');
        const ws = new WebSocket(`ws://localhost:8004/ws/queue/STN001`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        ws.on('open', function open() {
            console.log('✅ WebSocket connected successfully!');
            console.log('📡 Listening for messages...');
        });

        ws.on('message', function message(data) {
            console.log('📨 Received message:', data.toString());
        });

        ws.on('error', function error(err) {
            console.log('❌ WebSocket error:', err.message);
        });

        ws.on('close', function close() {
            console.log('🔌 WebSocket connection closed');
        });

        // Keep connection alive for 10 seconds
        setTimeout(() => {
            console.log('🔄 Closing connection...');
            ws.close();
        }, 10000);

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testWebSocket();
