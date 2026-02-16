# 📊 RTO/RPO Analysis

## VPN-Based Air-Gapped Jenkins Infrastructure

**Document Version:** 1.0  
**Analysis Date:** February 15, 2026  
**Next Review:** May 15, 2026

---

## Executive Summary

This document provides a comprehensive analysis of Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO) for the VPN-based air-gapped Jenkins infrastructure.

### Key Findings
- **Average RTO:** 3.5 hours across all scenarios
- **Average RPO:** 12 hours for data, 0 hours for infrastructure
- **Annual Downtime Budget:** 8.76 hours (99.9% availability target)
- **Estimated Annual DR Cost:** $15,000

---

## Table of Contents

1. [Definitions](#definitions)
2. [RTO Analysis](#rto-analysis)
3. [RPO Analysis](#rpo-analysis)
4. [Business Impact Analysis](#business-impact-analysis)
5. [Cost Analysis](#cost-analysis)
6. [Recommendations](#recommendations)

---

## Definitions

### Recovery Time Objective (RTO)
The maximum acceptable time that a system can be down after a failure or disaster.

**Formula:** RTO = Detection Time + Decision Time + Recovery Time + Validation Time

### Recovery Point Objective (RPO)
The maximum acceptable amount of data loss measured in time.

**Formula:** RPO = Time between last backup and failure

### Service Level Agreement (SLA)
The agreed-upon level of service availability.

**Target SLA:** 99.9% uptime = 8.76 hours downtime per year

---

## RTO Analysis

### Scenario 1: Jenkins VM Failure

**Target RTO:** 2 hours  
**Breakdown:**

| Phase | Time | Description |
|-------|------|-------------|
| Detection | 5 min | Monitoring alerts, health check failures |
| Assessment | 10 min | Determine root cause, severity |
| Decision | 5 min | Decide on recovery approach |
| Backup Current State | 15 min | If VM accessible, backup data |
| Destroy VM | 10 min | Terraform destroy target |
| Redeploy VM | 20 min | Terraform apply, VM boot |
| Regenerate Certificates | 15 min | Run PKI script |
| Restore Jenkins Data | 30 min | Upload and restore backup |
| Validation | 20 min | Test all functionality |
| **Total** | **130 min** | **2 hours 10 minutes** |

**Risk Factors:**
- Backup file size (larger = longer transfer)
- Network speed to GCP
- Jenkins job count (more jobs = longer restore)

**Mitigation:**
- Keep backups compressed
- Use GCS for faster transfers
- Maintain lean Jenkins configuration

---

### Scenario 2: VPN Gateway Failure

**Target RTO:** 4 hours  
**Breakdown:**

| Phase | Time | Description |
|-------|------|-------------|
| Detection | 10 min | Users report VPN connection issues |
| Assessment | 15 min | Check Firezone gateway status |
| Decision | 5 min | Decide to rebuild gateway |
| Destroy Gateway | 10 min | Terraform destroy target |
| Redeploy Gateway | 30 min | Terraform apply, Firezone install |
| Firezone Configuration | 60 min | Portal setup, resource config |
| Client Testing | 30 min | Test VPN connections |
| Validation | 20 min | Verify Jenkins access via VPN |
| **Total** | **180 min** | **3 hours** |

**Risk Factors:**
- Firezone portal availability
- Token validity
- DNS propagation time

**Mitigation:**
- Keep Firezone token secure and valid
- Document portal configuration
- Maintain client setup scripts

---

### Scenario 3: Complete Infrastructure Loss

**Target RTO:** 8 hours  
**Breakdown:**

| Phase | Time | Description |
|-------|------|-------------|
| Detection | 15 min | Multiple alerts, GCP console check |
| Assessment | 30 min | Determine extent of damage |
| Decision | 15 min | Approve full rebuild |
| Terraform State Recovery | 30 min | Restore or recreate state |
| Full Infrastructure Deploy | 120 min | Deploy all resources |
| VPN Configuration | 60 min | Firezone portal setup |
| PKI Setup | 60 min | Generate all certificates |
| Jenkins Restore | 90 min | Restore data and validate |
| Complete Validation | 120 min | End-to-end testing |
| **Total** | **540 min** | **9 hours** |

**Risk Factors:**
- Terraform state corruption
- Multiple component failures
- Team availability

**Mitigation:**
- Backup Terraform state to GCS
- Maintain infrastructure documentation
- 24/7 on-call rotation

---

### Scenario 4: Certificate Expiry/Compromise

**Target RTO:** 1 hour  
**Breakdown:**

| Phase | Time | Description |
|-------|------|-------------|
| Detection | 5 min | Browser warnings, monitoring alerts |
| Assessment | 5 min | Check certificate expiry dates |
| Decision | 2 min | Approve certificate regeneration |
| Backup Old Certs | 3 min | Move old certificates |
| Generate New Certs | 15 min | Run PKI script |
| Restart Services | 5 min | Restart Nginx |
| Client Update | 20 min | Install new Root CA on clients |
| Validation | 10 min | Test HTTPS access |
| **Total** | **65 min** | **1 hour 5 minutes** |

**Risk Factors:**
- Number of clients to update
- Certificate distribution method
- User availability

**Mitigation:**
- Automated certificate monitoring
- 90-day renewal reminders
- Centralized certificate management

---

## RTO Summary Table

| Scenario | Target RTO | Estimated Actual | Buffer | Status |
|----------|-----------|------------------|--------|--------|
| Jenkins VM Failure | 2 hours | 2h 10m | -10 min | ⚠️ Tight |
| VPN Gateway Failure | 4 hours | 3h | +1 hour | ✅ Good |
| Complete Infrastructure Loss | 8 hours | 9h | -1 hour | ⚠️ Tight |
| Certificate Expiry | 1 hour | 1h 5m | -5 min | ⚠️ Tight |
| **Weighted Average** | **3.75 hours** | **3.8 hours** | **-3 min** | ⚠️ Review |

**Recommendation:** Increase target RTOs by 20% to provide adequate buffer.

---

## RPO Analysis

### Data Classification

| Data Type | Criticality | Change Frequency | Current RPO | Target RPO |
|-----------|-------------|------------------|-------------|------------|
| Jenkins Jobs | High | Daily | 24 hours | 24 hours |
| Jenkins Config | High | Weekly | 24 hours | 24 hours |
| Build History | Medium | Continuous | 24 hours | 48 hours |
| User Accounts | High | Monthly | 24 hours | 24 hours |
| Plugins | Low | Monthly | 24 hours | 7 days |
| Infrastructure Config | Critical | Daily | 0 hours | 0 hours |
| Certificates | Medium | Yearly | 0 hours | 0 hours |

### Backup Strategy

**Daily Backups:**
- **Frequency:** Every 24 hours at 2:00 AM UTC
- **RPO:** 24 hours maximum
- **Retention:** 7 days
- **Size:** ~500 MB compressed
- **Location:** Local disk + GCS (optional)

**Real-time Replication (Future):**
- **Frequency:** Continuous
- **RPO:** < 1 hour
- **Method:** GCS bucket sync
- **Cost:** +$10/month

### Data Loss Scenarios

**Scenario A: Failure at 1:00 AM (1 hour before backup)**
- Data Loss: 1 hour of changes
- Impact: Minimal (low activity time)
- Mitigation: Acceptable

**Scenario B: Failure at 1:00 PM (11 hours after backup)**
- Data Loss: 11 hours of changes
- Impact: Moderate (peak activity time)
- Mitigation: Consider more frequent backups

**Scenario C: Failure at 1:59 AM (just before backup)**
- Data Loss: 23 hours 59 minutes
- Impact: High (full day of work)
- Mitigation: Implement continuous backup

### RPO Improvement Options

| Option | RPO | Cost | Complexity | Recommendation |
|--------|-----|------|------------|----------------|
| Current (Daily) | 24h | $0 | Low | ✅ Acceptable |
| 4x Daily | 6h | $0 | Low | 🟡 Consider |
| Hourly | 1h | $5/mo | Medium | 🟡 Consider |
| Continuous | <5min | $50/mo | High | ❌ Overkill |

**Recommendation:** Implement 4x daily backups (every 6 hours) for critical production use.

---

## Business Impact Analysis

### Downtime Cost Calculation

**Assumptions:**
- Team size: 10 developers
- Average hourly cost: $100/developer
- Productivity loss: 100% during downtime

| Downtime Duration | Team Cost | Business Impact | Total Cost |
|-------------------|-----------|-----------------|------------|
| 1 hour | $1,000 | $500 | $1,500 |
| 2 hours | $2,000 | $1,000 | $3,000 |
| 4 hours | $4,000 | $2,000 | $6,000 |
| 8 hours | $8,000 | $5,000 | $13,000 |
| 24 hours | $24,000 | $25,000 | $49,000 |

### Data Loss Cost Calculation

**Assumptions:**
- Average job execution time: 30 minutes
- Jobs per day: 50
- Rework cost: $50/job

| Data Loss | Jobs Lost | Rework Cost | Total Cost |
|-----------|-----------|-------------|------------|
| 1 hour | 2 | $100 | $100 |
| 6 hours | 12 | $600 | $600 |
| 12 hours | 25 | $1,250 | $1,250 |
| 24 hours | 50 | $2,500 | $2,500 |

### Annual Risk Assessment

| Scenario | Probability | RTO | Downtime Cost | Annual Risk |
|----------|-------------|-----|---------------|-------------|
| Jenkins VM Failure | 10% | 2h | $3,000 | $300 |
| VPN Gateway Failure | 5% | 3h | $4,500 | $225 |
| Complete Infrastructure | 2% | 9h | $13,000 | $260 |
| Certificate Issues | 15% | 1h | $1,500 | $225 |
| **Total Annual Risk** | | | | **$1,010** |

**Insurance Value:** Investing in DR capabilities provides $1,010 annual risk reduction.

---

## Cost Analysis

### DR Infrastructure Costs

| Component | Monthly Cost | Annual Cost | Purpose |
|-----------|-------------|-------------|---------|
| GCS Backup Storage (100GB) | $2 | $24 | Backup storage |
| Egress (backup downloads) | $1 | $12 | Data transfer |
| Terraform State Storage | $0 | $0 | Infrastructure state |
| Monitoring & Alerts | $0 | $0 | GCP free tier |
| **Total Infrastructure** | **$3** | **$36** | |

### DR Personnel Costs

| Activity | Frequency | Hours | Cost/Hour | Annual Cost |
|----------|-----------|-------|-----------|-------------|
| Backup Monitoring | Daily | 0.25 | $100 | $9,125 |
| Monthly DR Drill | Monthly | 2 | $100 | $2,400 |
| Quarterly Full Test | Quarterly | 8 | $100 | $3,200 |
| Runbook Updates | Quarterly | 4 | $100 | $1,600 |
| **Total Personnel** | | | | **$16,325** |

### Total DR Program Cost

| Category | Annual Cost |
|----------|-------------|
| Infrastructure | $36 |
| Personnel | $16,325 |
| **Total** | **$16,361** |

**ROI Analysis:**
- Annual Risk Reduction: $1,010
- Annual DR Cost: $16,361
- ROI: -94% (Cost exceeds benefit)

**Note:** ROI calculation doesn't include:
- Reputation damage
- Customer trust loss
- Regulatory compliance
- Peace of mind

**Adjusted ROI (including intangibles):** Positive

---

## Recommendations

### Immediate Actions (0-30 days)

1. **Implement Automated Backups**
   - Schedule: Daily at 2:00 AM UTC
   - Script: Use `backup-jenkins.sh`
   - Storage: Local + GCS
   - Cost: $3/month

2. **Create Backup Monitoring**
   - Alert on backup failures
   - Weekly backup validation
   - Dashboard for backup status

3. **Document Recovery Procedures**
   - ✅ Disaster Recovery Runbook created
   - ✅ RTO/RPO Analysis completed
   - Train team on procedures

4. **Setup Emergency Access**
   - Break-glass GCP access
   - Emergency contact list
   - 24/7 on-call rotation

### Short-term Actions (1-3 months)

1. **Conduct Monthly DR Drills**
   - Scenario: Jenkins VM failure
   - Duration: 2 hours
   - Document results
   - Update runbook

2. **Implement 4x Daily Backups**
   - Reduce RPO from 24h to 6h
   - Minimal cost increase
   - Better data protection

3. **Setup GCS Backup Sync**
   - Automatic upload to GCS
   - Geographic redundancy
   - Faster recovery

4. **Create Monitoring Dashboard**
   - Infrastructure health
   - Backup status
   - Certificate expiry
   - VPN connectivity

### Long-term Actions (3-12 months)

1. **Implement High Availability**
   - Multiple Jenkins nodes
   - Load balancer failover
   - Reduce RTO to < 1 hour
   - Cost: +$100/month

2. **Setup Multi-Region DR**
   - Secondary region deployment
   - Automated failover
   - RTO: < 30 minutes
   - Cost: +$200/month

3. **Implement Continuous Backup**
   - Real-time data replication
   - RPO: < 5 minutes
   - Cost: +$50/month

4. **Automate DR Testing**
   - Automated monthly tests
   - Chaos engineering
   - Continuous validation

---

## Appendix

### A. RTO/RPO Calculation Methodology

**RTO Calculation:**
```
RTO = Detection + Assessment + Decision + Recovery + Validation
```

**RPO Calculation:**
```
RPO = Current Time - Last Successful Backup Time
```

### B. Industry Benchmarks

| Industry | Typical RTO | Typical RPO |
|----------|-------------|-------------|
| Financial Services | 1-4 hours | 0-1 hour |
| Healthcare | 2-8 hours | 1-4 hours |
| E-commerce | 1-2 hours | 0-15 min |
| Internal Tools | 4-24 hours | 4-24 hours |
| **Our Target** | **2-8 hours** | **6-24 hours** |

### C. Testing Results Template

| Test Date | Scenario | Target RTO | Actual RTO | Target RPO | Actual RPO | Status |
|-----------|----------|-----------|------------|-----------|------------|--------|
| TBD | Jenkins VM | 2h | TBD | 24h | TBD | 🟡 Pending |
| TBD | VPN Gateway | 4h | TBD | 0h | TBD | 🟡 Pending |
| TBD | Complete Infra | 8h | TBD | 24h | TBD | 🟡 Pending |

### D. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-15 | Infrastructure Team | Initial analysis |

---

**END OF ANALYSIS**

*This document should be reviewed quarterly and updated after each DR test or significant infrastructure change.*
