# Exa MCP Server Monitoring Guide

## Overview

This document outlines the monitoring strategy for the Exa MCP server in a production environment. Proper monitoring is essential to ensure reliability, performance, and security of the Exa search integration.

## Monitoring Components

### 1. Server Health Monitoring

**Metrics to Track:**
- CPU usage
- Memory consumption
- Response times
- Error rates
- Request volume

**Implementation:**
```javascript
// Add to index.ts
import fs from 'fs';

class MetricsCollector {
  private stats = {
    requests: 0,
    errors: 0,
    avgResponseTime: 0,
    totalResponseTime: 0
  };
  
  recordRequest(responseTime: number, isError: boolean) {
    this.stats.requests++;
    this.stats.totalResponseTime += responseTime;
    this.stats.avgResponseTime = this.stats.totalResponseTime / this.stats.requests;
    if (isError) this.stats.errors++;
    
    // Log metrics every 100 requests
    if (this.stats.requests % 100 === 0) {
      this.logMetrics();
    }
  }
  
  logMetrics() {
    const metrics = {
      timestamp: new Date().toISOString(),
      ...this.stats,
      errorRate: this.stats.requests > 0 ? this.stats.errors / this.stats.requests : 0
    };
    
    fs.appendFileSync('metrics.log', JSON.stringify(metrics) + '\n');
    console.error('Metrics:', metrics);
  }
}

const metrics = new MetricsCollector();

// Integrate with server request handling
server.setRequestHandler(
  CallToolRequestSchema,
  async (request) => {
    const startTime = Date.now();
    let isError = false;
    
    try {
      // Existing request handling...
    } catch (error) {
      isError = true;
      throw error;
    } finally {
      const responseTime = Date.now() - startTime;
      metrics.recordRequest(responseTime, isError);
    }
  }
);
```

### 2. API Quota and Rate Limiting

**Metrics to Track:**
- Daily API calls to Exa
- Remaining quota
- Rate limit errors

**Implementation:**
```javascript
// Add to index.ts
class QuotaTracker {
  private dailyRequests = 0;
  private resetDate = new Date().setHours(0, 0, 0, 0) + 86400000; // next day midnight
  
  trackRequest() {
    // Reset counter if it's a new day
    const now = Date.now();
    if (now > this.resetDate) {
      this.dailyRequests = 0;
      this.resetDate = new Date().setHours(0, 0, 0, 0) + 86400000;
    }
    
    this.dailyRequests++;
    
    // Log every 10 requests
    if (this.dailyRequests % 10 === 0) {
      console.error(`API Usage: ${this.dailyRequests} calls today. Reset at ${new Date(this.resetDate).toISOString()}`);
    }
    
    return this.dailyRequests;
  }
  
  getRemainingQuota(limit: number) {
    return Math.max(0, limit - this.dailyRequests);
  }
}

const quotaTracker = new QuotaTracker();
```

### 3. Error Logging and Alerting

**Error Categories:**
- API errors (4xx, 5xx)
- Authentication errors
- Rate limiting errors
- System errors

**Implementation:**
```javascript
// Add to index.ts
class ErrorLogger {
  private errorCounts = {
    api4xx: 0,
    api5xx: 0,
    auth: 0,
    rateLimit: 0,
    system: 0
  };
  
  logError(error: any) {
    const timestamp = new Date().toISOString();
    let errorType = 'system';
    let errorMessage = error.message || 'Unknown error';
    
    if (axios.isAxiosError(error)) {
      const status = error.response?.status || 0;
      
      if (status === 401 || status === 403) {
        errorType = 'auth';
      } else if (status === 429) {
        errorType = 'rateLimit';
      } else if (status >= 400 && status < 500) {
        errorType = 'api4xx';
      } else if (status >= 500) {
        errorType = 'api5xx';
      }
      
      errorMessage = error.response?.data?.message || error.message || 'Unknown API error';
    }
    
    // Increment counter
    this.errorCounts[errorType]++;
    
    // Log error
    const logEntry = {
      timestamp,
      type: errorType,
      message: errorMessage,
      counts: { ...this.errorCounts }
    };
    
    fs.appendFileSync('errors.log', JSON.stringify(logEntry) + '\n');
    console.error('Error:', logEntry);
    
    // Alert on critical errors
    if (errorType === 'auth' || errorType === 'rateLimit' || errorType === 'api5xx') {
      this.sendAlert(errorType, errorMessage);
    }
  }
  
  private sendAlert(type: string, message: string) {
    // Implement your alerting mechanism here
    // This could be an email, Slack notification, PagerDuty, etc.
    console.error(`ALERT: ${type} error - ${message}`);
  }
}

const errorLogger = new ErrorLogger();
```

## Monitoring Tools Integration

### Prometheus Integration

For systems using Prometheus for monitoring:

```typescript
import { register, Counter, Histogram } from 'prom-client';
import http from 'http';

// Create metrics
const searchCounter = new Counter({
  name: 'exa_search_total',
  help: 'Total number of search requests',
  labelNames: ['status']
});

const searchDuration = new Histogram({
  name: 'exa_search_duration_seconds',
  help: 'Search request duration in seconds',
  buckets: [0.1, 0.5, 1, 2, 5]
});

// Example usage in request handler
const end = searchDuration.startTimer();
try {
  // Process request
  searchCounter.inc({ status: 'success' });
} catch (error) {
  searchCounter.inc({ status: 'error' });
  throw error;
} finally {
  end();
}

// Create metrics endpoint
http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(register.metrics());
}).listen(9464);
```

### Log Aggregation with ELK Stack

Sample Logstash configuration for parsing JSON logs:

```
input {
  file {
    path => "/path/to/exa-mcp-server/metrics.log"
    codec => "json"
    type => "metrics"
  }
  file {
    path => "/path/to/exa-mcp-server/errors.log"
    codec => "json"
    type => "errors"
  }
}

filter {
  date {
    match => [ "timestamp", "ISO8601" ]
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "exa-mcp-server-%{+YYYY.MM.dd}"
  }
}
```

## Dashboard Templates

### Grafana Dashboard Example

```json
{
  "dashboard": {
    "id": null,
    "title": "Exa MCP Server Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(exa_search_total[5m])",
            "legendFormat": "{{status}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(exa_search_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(exa_search_total{status=\"error\"}[5m]) / rate(exa_search_total[5m])",
            "legendFormat": "Error Rate"
          }
        ]
      }
    ]
  }
}
```

## Alert Configuration

### Example Alerting Rules

```yaml
groups:
- name: exa-mcp-server
  rules:
  - alert: HighErrorRate
    expr: rate(exa_search_total{status="error"}[5m]) / rate(exa_search_total[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High Error Rate"
      description: "Error rate is above 10% for 5 minutes"

  - alert: APIQuotaNearLimit
    expr: exa_api_remaining_quota < 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "API Quota Running Low"
      description: "Less than 100 API calls remaining in quota"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, sum(rate(exa_search_duration_seconds_bucket[5m])) by (le)) > 2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High Response Time"
      description: "95th percentile of response time is above 2 seconds for 5 minutes"
```

## Maintenance Procedures

### Daily Check

1. Review error logs for unexpected patterns
2. Check API quota consumption
3. Verify response time metrics are within expected range

### Weekly Maintenance

1. Review error trends
2. Check for MCP SDK updates
3. Verify Exa API version compatibility
4. Rotate logs
5. Update API documentation if needed

### Incident Response

1. Identify the issue from monitoring alerts
2. Check logs for detailed error information
3. If API issue, check Exa status page
4. Apply appropriate fix:
   - For rate limiting: implement backoff
   - For API errors: check for changes in API
   - For system errors: review server logs

## Documentation

Keep all documentation updated, including:
- API version compatibility
- Rate limits and quotas
- Known issues
- Common error cases and resolutions

## Third-Party Service Dependencies

| Service | Function | Contact/Status Page |
|---------|----------|---------------------|
| Exa AI API | Search functionality | https://status.exa.ai |
| NPM | Package dependencies | https://status.npmjs.org |

## Security Monitoring

1. Regularly audit API key usage
2. Implement context-aware security checks
3. Monitor for unusual activity patterns
4. Review access logs regularly