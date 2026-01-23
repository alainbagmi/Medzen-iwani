# MedZen Telemedicine - Incident Response Playbook

**Document Version:** 1.0
**Last Updated:** 2026-01-23
**Status:** Active
**Classification:** Confidential

---

## EXECUTIVE SUMMARY

This playbook defines MedZen's response procedures for security incidents involving PHI (Protected Health Information) and HIPAA/GDPR compliance. All team members must follow these procedures to ensure rapid containment and regulatory compliance.

**Key Contacts:**
- **Security Lead:** [Name/Email]
- **CTO:** [Name/Email]
- **Legal/Compliance:** [Name/Email]
- **AWS Support:** [Account ID + Contact]
- **Supabase Support:** [Project ID + Contact]

---

## SECTION 1: INCIDENT CATEGORIES & SEVERITY LEVELS

### P0 (CRITICAL) - Immediate Response Required

**Definition:** Active, ongoing PHI exposure or data breach

**Examples:**
- Database with unencrypted PHI accessible from internet
- Wildcard CORS allowing any domain to access API with PHI
- Unprotected S3 bucket containing medical records
- Ransomware/malware on production infrastructure
- Confirmed unauthorized access to patient data

**Response Time:** < 15 minutes
**Escalation:** Immediate (CTO → CEO → Legal)
**Actions:**
1. Isolate affected systems (pull from production)
2. Enable enhanced logging/monitoring
3. Notify security team
4. Begin incident investigation
5. Prepare breach notification

### P1 (HIGH) - Urgent Response Required

**Definition:** Unauthorized access attempt or significant vulnerability

**Examples:**
- Failed login attempts (>10 in 5 minutes)
- SQL injection attempt detected
- XSS payload sent to API
- Compromised API key/token
- DDoS attack in progress
- GuardDuty alert (suspicious activity)

**Response Time:** < 1 hour
**Escalation:** CTO + Security Team
**Actions:**
1. Investigate source IP/user identity
2. Block suspicious access (firewall rules)
3. Review CloudTrail logs
4. Check for lateral movement
5. Monitor for data exfiltration

### P2 (MEDIUM) - Standard Response

**Definition:** Policy violation or suspicious activity

**Examples:**
- Unusual API usage patterns
- Employee accessing data outside normal hours
- Failed MFA attempts
- Rate limit violations
- Unpatched security advisory
- Configuration drift detected

**Response Time:** < 4 hours
**Escalation:** Security Team
**Actions:**
1. Log incident details
2. Investigate root cause
3. Implement remediation
4. Document findings
5. Update security posture

### P3 (LOW) - Monitoring/Resolution

**Definition:** Minor compliance issue or informational alert

**Examples:**
- Expired SSL certificate (7+ days)
- Security header missing (single endpoint)
- Audit log gap (< 1 hour)
- Deprecated dependency available
- Access control policy review needed

**Response Time:** < 24 hours
**Escalation:** None (team resolution)
**Actions:**
1. Ticket creation in JIRA
2. Schedule remediation
3. Update documentation
4. Monitor progress

---

## SECTION 2: 6-PHASE INCIDENT RESPONSE PROCEDURE

### PHASE 1: DETECTION & TRIAGE (0-15 minutes)

**Responsible:** On-call Security Engineer

**Actions:**

1. **Receive Alert**
   - CloudWatch alarm triggered
   - GuardDuty finding detected
   - User reports suspicious activity
   - Automated monitoring system alerts

2. **Initial Assessment**
   ```
   Checklist:
   ☐ What happened? (Describe incident)
   ☐ When did it happen? (Start time)
   ☐ Where? (Service/database/server)
   ☐ Who detected it? (Source of alert)
   ☐ Is it ongoing? (Active/contained)
   ☐ PHI involved? (Yes/No/Unknown)
   ☐ Production system? (Yes/No)
   ```

3. **Severity Assignment**
   ```
   Algorithm:
   IF ongoing AND PHI accessible
     THEN P0
   ELSE IF unauthorized access attempt OR vulnerability active
     THEN P1
   ELSE IF suspicious activity OR policy violation
     THEN P2
   ELSE
     THEN P3
   ```

4. **Initial Escalation**
   - **P0:** Call CTO immediately + page all security team
   - **P1:** Notify CTO + Security Lead via Slack
   - **P2/P3:** Create JIRA ticket, Slack notification

**STOP:** Do not proceed until severity assigned

---

### PHASE 2: CONTAINMENT (0-4 hours)

**Responsible:** CTO + Security Team

**Objective:** Stop spread, prevent further exposure

**Actions:**

#### P0 Containment (< 15 minutes)

1. **Immediate Isolation**
   ```bash
   # Stop affected service
   aws ecs update-service --cluster medzen-prod \
     --service affected-service --desired-count 0

   # Revoke compromised credentials
   aws iam update-access-key --access-key-id KEY_ID \
     --status Inactive

   # Block suspicious IP
   aws wafv2 create-ip-set --region eu-central-1 \
     --name BlockedIPs --scope REGIONAL \
     --ip-address-version IPV4 --addresses ["1.2.3.4/32"]
   ```

2. **Enable Enhanced Logging**
   ```
   ☐ CloudTrail verbose logging enabled
   ☐ Database query logging enabled
   ☐ Application logs redirected to separate stream
   ☐ VPC Flow Logs enabled for 5-tuple analysis
   ```

3. **Notify Stakeholders**
   - CTO
   - Security Team
   - Database Administrators
   - AWS Account Manager
   - Supabase Support

#### P1 Containment (< 1 hour)

1. **Source Investigation**
   - Extract IP address / User ID
   - Check CloudTrail for activities
   - Review failed login logs
   - Identify affected resources

2. **Access Restriction**
   ```bash
   # Revoke user session
   # Rotate API keys
   # Update firewall rules
   # Reset passwords if compromised
   ```

3. **Monitoring Enhancement**
   - Add real-time alerting for source IP
   - Monitor user account for anomalies
   - Set up anomaly detection

#### P2/P3 Containment (Standard)

- Document incident
- Create change ticket
- Schedule remediation
- Update monitoring rules

**STOP:** Continue only after containment confirmed

---

### PHASE 3: INVESTIGATION (0-24 hours)

**Responsible:** Security Lead + Engineers

**Objective:** Determine scope, root cause, timeline

**Investigation Template:**

```markdown
## Incident Investigation Report

**Incident ID:** INC-2026-001
**Date/Time:** 2026-01-23 10:30 UTC
**Investigator:** [Name]
**Severity:** P[0/1/2/3]

### Timeline

| Time | Event | Source |
|------|-------|--------|
| 10:30 | Alert received | CloudWatch |
| 10:35 | CTO notified | Slack |
| 10:40 | Service isolated | Manual |
| 10:45 | Investigation began | Team |

### Root Cause Analysis

**What Failed:**
- Wildcard CORS allowed unauthorized domain access
- Rate limiting not enforced
- Input validation missing

**Why It Failed:**
- Security module not integrated during deployment
- Code review missed vulnerability
- Staging did not have full security testing

**Contributing Factors:**
- Legacy function from pre-security-hardening phase
- Deployment automation did not verify security modules

### Scope Assessment

**Affected Systems:**
- chime-meeting-token (edge function)
- video_call_sessions table (RDS)

**Affected Users:**
- Unknown (investigation ongoing)
- Estimated: < 100 users

**Data Exposed:**
- Appointment IDs
- Provider names
- Date/time of calls
- NOT: Medical records, clinical notes

**Duration:**
- Start: 2026-01-23 10:30 UTC
- Detected: 2026-01-23 10:35 UTC
- Contained: 2026-01-23 10:45 UTC
- Duration: 15 minutes

### Evidence Collected

```bash
# AWS CloudTrail logs
aws cloudtrail lookup-events --lookup-attributes \
  AttributeKey=EventName,AttributeValue=InvokeFunction \
  --region eu-central-1 > cloudtrail-events.json

# RDS Query logs
SELECT * FROM pg_stat_statements WHERE query LIKE '%video_call%';

# WAF logs
aws wafv2 get-sampled-requests --rule-metric-name ChimeMeetingToken
```

### Mitigation Implemented

✅ Service isolated from production
✅ Wildcard CORS replaced with origin validation
✅ Rate limiting integrated and deployed
✅ Input validation enabled
✅ All responses include security headers
✅ CloudTrail logs archived

### Lessons Learned

1. Security integration must be verified in all environments
2. Code review process needs security checklist
3. Automated testing should include CORS + rate limiting verification
4. Deployment process should validate security module integration

### Recommendations

1. Implement automated CORS security testing in CI/CD
2. Add security-focused code review gates
3. Mandatory security training for all engineers
4. Quarterly security audits of all functions
5. Implement supply chain security measures
```

**Investigation Checklist:**
```
☐ Timeline established (start → detection → containment)
☐ Root cause identified
☐ Affected systems documented
☐ Affected users identified
☐ Data exposure scope determined
☐ Logs archived for evidence
☐ Contributing factors documented
☐ Mitigation verified effective
☐ Follow-up improvements identified
```

---

### PHASE 4: NOTIFICATION (0-72 hours)

**Responsible:** Legal + Compliance + Security

**GDPR Requirement:** Notify within 72 hours of discovery
**HIPAA Requirement:** Notify within 60 days of discovery

#### Breach Notification Decision Tree

```
IF data exposed AND unauthorized access confirmed
  THEN notify all affected individuals
ELSE IF data exposed BUT no unauthorized access
  THEN notify if accessible from unsecured endpoint > 1 hour
ELSE
  THEN no notification required (document decision)
END
```

#### Patient Notification Template

```
Subject: Important Security Notice - MedZen Telemedicine

Dear [Patient Name],

We are writing to inform you of a security incident that may have
affected your personal health information.

On January 23, 2026, we discovered that an edge function had a
configuration error that allowed unauthorized access to appointment
information. Specifically, the following information may have been exposed:

- Your appointment ID
- Date and time of your video consultation
- Name of your healthcare provider

This information does NOT include:
- Your medical diagnoses or clinical notes
- Medication information
- Test results or vital signs
- Insurance information

WHAT WE'VE DONE:
1. Immediately isolated the affected system from production
2. Fixed the CORS configuration to only allow authorized domains
3. Integrated comprehensive rate limiting and input validation
4. Reviewed all access logs for suspicious activity
5. Found no evidence of unauthorized data access

WHAT YOU SHOULD DO:
1. Watch for any suspicious communications
2. Monitor your account for unauthorized access
3. Contact us if you notice any unusual activity
4. You may request a full audit of your account

HOW TO CONTACT US:
- Security Team: security@medzenhealth.app
- Response Hotline: +[Country] [Number]
- Online Portal: medzenhealth.app/security-incident

For more information about this incident and our response, please visit
our detailed incident report at: [URL]

We take your privacy and security very seriously. We apologize for
this incident and the concern it may cause.

Sincerely,
MedZen Security Team
```

#### Regulatory Notification

**To:** [Data Protection Authority]
**Form:** GDPR Breach Notification
**Timeline:** Within 72 hours

**Content:**
- Incident description
- Data categories and numbers affected
- Likely consequences
- Measures taken/planned
- Contact information

---

### PHASE 5: REMEDIATION (1-7 days)

**Responsible:** Engineering + Security

**Actions:**

1. **Security Patch Deployment**
   ```bash
   # Deploy fixed edge functions
   npx supabase functions deploy chime-meeting-token
   npx supabase functions deploy generate-soap-draft-v2
   npx supabase functions deploy bedrock-ai-chat
   # ... all 59 functions
   ```

2. **Configuration Hardening**
   - Update all CORS policies (origin validation)
   - Implement rate limiting on all endpoints
   - Add input validation to critical paths
   - Deploy security headers middleware

3. **Testing & Verification**
   ```bash
   # Run full security test suite
   ./test-cors-security.sh
   ./test-rate-limiting.sh
   ./test-input-validation.sh
   ./verify-encryption.sh
   ./verify-audit-logging.sh
   ```

4. **Monitoring Enhancement**
   - Add CloudWatch alarms for:
     - Wildcard CORS attempts
     - Rate limit violations
     - XSS/SQL injection attempts
     - Unauthorized domain access
   - Set up dashboard for incident metrics

5. **Documentation Update**
   - Update deployment guide
   - Add security incident to runbook
   - Create preventive measures documentation
   - Add to security training materials

---

### PHASE 6: POST-INCIDENT REVIEW (7-14 days)

**Responsible:** CTO + Security Lead + Team

**Review Meeting Agenda:**

1. **Incident Summary** (15 min)
   - What happened
   - Impact assessment
   - Resolution timeline

2. **Root Cause Analysis** (30 min)
   - Technical root cause
   - Process failures
   - Contributing factors
   - Why it wasn't caught earlier

3. **Mitigation Review** (15 min)
   - Were containment actions effective?
   - Could we have responded faster?
   - Could we have prevented it?

4. **Action Items** (30 min)
   - Prevention measures
   - Detection improvements
   - Response process updates
   - Training requirements

5. **Knowledge Sharing** (15 min)
   - Document lessons learned
   - Update security procedures
   - Share with team/organization

**Post-Incident Report:**
```markdown
# Incident Post-Mortem Report

**Timeline:** 2026-01-23 10:30 UTC - 2026-01-25 15:00 UTC

## What Went Well
- Fast detection (5 minutes)
- Quick containment (15 minutes)
- Clear escalation path
- Effective cross-team coordination

## What Could Improve
- Automated detection could be earlier
- Security review checklist was skipped
- Staging environment didn't match production
- Communication delays with AWS support

## Action Items

| Action | Owner | Due | Priority |
|--------|-------|-----|----------|
| Implement automated CORS testing in CI/CD | Engineering | 2026-02-06 | P0 |
| Add security checklist to code review | Engineering Manager | 2026-01-30 | P0 |
| Mandatory security training for team | HR/Security | 2026-02-20 | P1 |
| Quarterly security audit schedule | Security Lead | 2026-02-13 | P1 |
| Update incident response procedures | CTO | 2026-02-06 | P2 |

## Prevention Measures

1. **Code Review Process**
   - ☐ Mandatory security checklist
   - ☐ At least 1 security-trained reviewer
   - ☐ Automated scanning tools

2. **Testing Process**
   - ☐ CORS validation tests (unit)
   - ☐ Rate limiting tests (integration)
   - ☐ XSS/SQL injection tests (security)
   - ☐ 100% code coverage requirement

3. **Monitoring**
   - ☐ Real-time CORS violation alerts
   - ☐ Automated rate limit alerts
   - ☐ Anomalous access pattern detection
   - ☐ Quarterly log review

4. **Training**
   - ☐ Security fundamentals (all staff)
   - ☐ OWASP Top 10 (developers)
   - ☐ HIPAA compliance (clinical staff)
   - ☐ Incident response (on-call)

## Approval

**Reviewed By:** [CTO Name] on [Date]
**Approved By:** [CEO Name] on [Date]
**Distribution:** All staff, Board, AWS support
```

---

## SECTION 3: ESCALATION MATRIX

### Who To Contact When

| Incident Type | Severity | Immediate Contact | Secondary | Tertiary |
|---|---|---|---|---|
| Data Breach | P0 | CTO (call) | Legal | CEO |
| Active Attack | P0 | Security Lead (call) | CTO | AWS Support |
| Unauthorized Access | P1 | Security Lead (Slack) | CTO | N/A |
| Vulnerability Found | P1 | Engineering Lead | CTO | N/A |
| Failed Authentication | P2 | On-call Engineer | Security Lead | N/A |
| Policy Violation | P2 | Team Lead | Manager | N/A |
| Configuration Drift | P3 | Engineer | Team Lead | N/A |
| Log Gap Detected | P3 | On-call Engineer | N/A | N/A |

### Contact Information

```
On-Call Security Engineer: [Name] [Phone] [Email]
On-Call CTO: [Name] [Phone] [Email]
Security Lead: [Name] [Phone] [Email]

AWS Support Plan: Enterprise
- Account ID: [ID]
- Primary Contact: [Name]
- Direct Number: [Number]

Supabase Support: [Workspace] [Project ID]
- Project Ref: noaeltglphdlkbflipit
- Contact: [Email]

Legal/Compliance: [Name] [Phone] [Email]
```

---

## SECTION 4: COMPLIANCE CHECKLISTS

### HIPAA Breach Notification Checklist

```
☐ Incident documented with date/time
☐ Scope of breach determined
☐ Individuals affected identified
☐ Risk assessment completed
☐ Notification draft prepared
☐ Legal review completed
☐ Notification sent within 60 days
☐ HHS notification submitted
☐ Media notification completed (if > 500 people)
☐ Documentation retained for 6+ years
```

### GDPR Incident Response Checklist

```
☐ Personal data breach identified
☐ Personal data categories documented
☐ Number of people affected identified
☐ Likely consequences assessed
☐ Measures taken documented
☐ Measures planned documented
☐ Notification prepared (if > low risk)
☐ DPA notified within 72 hours
☐ Individuals notified without undue delay
☐ Breach register updated
☐ Documentation retained per GDPR Article 33
```

### Post-Breach Risk Assessment

For each data category exposed:

```markdown
## Patient Record Risk Assessment

| Category | Sensitivity | If Exposed | Mitigation | Risk Level |
|----------|-------------|-----------|-----------|-----------|
| Appointment ID | Low | Patient calendar exposed | De-identified in logs | LOW |
| Provider Name | Low | Provider directory exposed | Public information | LOW |
| Call Date/Time | Medium | Schedule pattern exposed | Pattern analysis possible | MEDIUM |
| Medical Record | High | Diagnosis/treatment exposed | Encrypted, not accessed | NONE |

Overall Risk: LOW (non-sensitive information only)
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-23 | Claude Code | Initial incident response playbook |

**Last Review:** 2026-01-23
**Next Review:** 2026-07-23 (6 months)
**Approval:** CTO + Security Lead + Legal Counsel

