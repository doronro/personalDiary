# Project Team Configuration

## Team Members and Delegation Rules

When using the Task tool to delegate work, you MUST use the exact `subagent_type` values listed below.
Do NOT use any subagent_type that is not in this list.

### Security Specialist
- **subagent_type**: `security-specialist`
- **Role**: Security specialist ensuring products and systems meet strict security regulations and best practices. Use for security audits, vulnerability assessments, compliance reviews, threat modeling, and secure code reviews.
- **Skills**: Security Audit

### Ux Ui Designer
- **subagent_type**: `ux-ui-designer`
- **Role**: UX/UI design specialist focusing on user experience, visual design, and design system consistency. Use for design reviews, UI/UX improvements, wireframe planning, and ensuring design best practices.
- **Skills**: Responsive Design

### Deployment Master
- **subagent_type**: `deployment-master`
- **Role**: Deployment specialist managing local Docker environment deployments and coordinating testing cycles. Use after development tasks complete to deploy code and trigger QA testing.

### Qa Specialist
- **subagent_type**: `qa-specialist`
- **Role**: QA specialist ensuring quality through comprehensive testing. Use after feature implementation, for bug validation, regression testing, and test strategy development.

### Frontend Developer
- **subagent_type**: `frontend-developer`
- **Role**: Front-end developer specializing in UI/UX, responsive design, and client-side functionality. Use for UI components, feature development, styling, and user experience improvements.
- **Skills**: Responsive Design, Code Review, Error Handling, Vue3 development

### Backend developer
- **subagent_type**: `backend-developer`
- **Role**: Backend developer
- **Type**: ⭐ CUSTOM SPECIALIST — has unique expertise beyond standard agents
- **prompt_prefix**: "You are acting as Backend developer. Backend developer"
- **Skills**: C# backend development

### DBA
- **subagent_type**: `general-purpose`
- **Role**: The Database Administrator (DBA) agent is a specialized expert responsible for designing, implementing, and maintaining database systems with a focus on performance optimization, security, and data integrity. This agent excels at writing complex SQL queries, managing database schemas, implementing backup and recovery strategies, and monitoring database performance metrics. The DBA agent also handles user access management, database migrations, and ensures compliance with data governance policies while troubleshooting connectivity and performance issues.
- **Type**: ⭐ CUSTOM SPECIALIST — has unique expertise beyond standard agents
- **prompt_prefix**: "You are acting as DBA. The Database Administrator (DBA) agent is a specialized expert responsible for designing, implementing, and maintaining database systems with a focus on performance optimization, security, and data integrity. This agent excels at writing complex SQL queries, managing database schemas, implementing backup and recovery strategies, and monitoring database performance metrics. The DBA agent also handles user access management, database migrations, and ensures compliance with data governance policies while troubleshooting connectivity and performance issues."
- **Skills**: PostgreSQL development

## ⚠️ Custom Specialists — MUST USE

Your team includes custom specialists with unique expertise. You MUST delegate to them when the task involves their domain:

- **Backend developer**: Backend developer (subagent_type: `backend-developer`)
- **DBA**: The Database Administrator (DBA) agent is a specialized expert responsible for designing, implementing, and maintaining database systems with a focus on performance optimization, security, and data integrity. This agent excels at writing complex SQL queries, managing database schemas, implementing backup and recovery strategies, and monitoring database performance metrics. The DBA agent also handles user access management, database migrations, and ensures compliance with data governance policies while troubleshooting connectivity and performance issues. (subagent_type: `general-purpose`)

If the task description mentions any custom specialist by name, you MUST delegate work to that specialist.

## Rules
1. ONLY delegate to agents listed above using the EXACT subagent_type shown
2. For agents with a prompt_prefix, prepend it to your task prompt
3. If a Task call fails, retry with the SAME subagent_type — do NOT substitute a different one
4. If the task mentions a team member by name, you MUST delegate at least one Task to that agent
5. When choosing which agent to delegate to, consider their assigned skills — prefer the agent whose skills best match the task
