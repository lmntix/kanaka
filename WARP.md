# WARP.md

This file provides guidance to WARP (warp.dev) when working with this repository as a business analyst for the Kanaka Microfinance Application.

## Repository Overview

This is the **Kanaka Microfinance Application Database Documentation Repository**.
It contains comprehensive documentation, database schemas, PostgreSQL procedures, and migration scripts for a sophisticated cooperative banking/microfinance system built on double-entry bookkeeping principles.
As a business analyst, my role is to analyze the data model and help developers understand how to implement or replicate this multi-org SaaS microfinance application. I will use Supabase MCP tools to fetch details from the database for this analysis.



### Supabase MCP Integration

As a business analyst, I'll use Supabase MCP tools to retrieve and analyze the database structure. This allows me to:

- Fetch table definitions and relationships
- Analyze data models without direct SQL access
- Generate comprehensive data model documentation
- Validate multi-organization data isolation
- Extract schema insights for implementation guidance


### Data Model Documentation

I will deliver the following analysis artifacts using Supabase MCP data:

1. **Entity-Relationship Diagrams**
   - Core business entities and relationships
   - Multi-organization table relationships
   - Financial product data flows

2. **Data Dictionary**
   - Comprehensive table and column definitions
   - Business rules and constraints
   - Multi-tenant design considerations

3. **Implementation Guidelines**
   - Key design patterns to replicate
   - Required database objects and relationships
   - Multi-organization isolation approach

### Design Pattern Analysis

I'll document these key patterns essential for implementation:

1. **Member-Centric Design**: All financial products link to members table
2. **Double-Entry Compliance**: Transaction processing that maintains accounting equation
3. **Multi-Tenant Architecture**: Complete organization isolation pattern
4. **Product Flexibility**: Scheme-based configuration approach
5. **Interest Automation**: Calculation and posting methodologies

## Implementation Recommendations

Based on my data model analysis, I'll provide these implementation recommendations:

### Multi-Organization Setup

1. **Tenant Onboarding Workflow**
   - Organization registration and initialization process
   - Required default data setup (CoA, settings, etc.)
   - User access management approach

2. **Data Isolation Strategy**
   - Recommended database-level isolation mechanisms
   - Application-level filtering requirements
   - Cross-tenant operations management (if needed)

### Critical System Components

1. **Transaction Engine**
   - Double-entry transaction processing implementation
   - Voucher generation with organization context
   - Transaction validation requirements

2. **Financial Processing**
   - Interest calculation and posting mechanisms
   - Month-end closing procedures
   - Report generation with organization context

## Supabase MCP Analysis Tools

I will use the following Supabase MCP tools for my analysis:

### Database Structure Analysis
- `list_tables`: To identify all tables in the database schema
- `execute_sql`: To run analytical queries on database structure
- `list_extensions`: To understand database capabilities

### Data Model Extraction
- Custom SQL queries via `execute_sql` to analyze:
  - Table relationships and dependencies
  - Foreign key constraints and data integrity rules
  - Multi-organization implementation patterns
  - Index structures for performance optimization

### Documentation Generation
- Transform database schema into comprehensive documentation
- Generate data dictionary from database metadata
- Extract business rules from database constraints
- Document multi-organization implementation patterns

## Key Implementation Considerations

- **Data Integrity**: Double-entry transactions must always balance
- **Multi-Tenant Security**: Organization data isolation is critical
- **Unique Identifiers**: Voucher sequences must be organization-specific
- **Financial Accuracy**: Interest calculations must follow industry standards
- **User Experience**: Account linking should be automated to minimize errors
- **Scalability**: Database design must support multiple organizations efficiently

As a business analyst, my goal is to provide a comprehensive understanding of this sophisticated multi-organization microfinance data model to guide implementation decisions.
