# Terraform Lambda Functions for EC2 Management

This repository contains Terraform code to deploy three AWS Lambda functions designed for managing and analyzing EC2 instances in a specified region.

## Lambda Functions

### 1. `list_instances`
- **Description**: Lists all EC2 instances in the specified region, including their tags and the runtime duration of each instance.
- **Features**:
  - Retrieves instance details.
  - Includes associated tags.
  - Calculates runtime for each instance.

### 2. `analyze_instance_usage`
- **Description**: Analyzes the cost of a selected EC2 instance, providing breakdowns for different states and the total cost since creation.
- **Features**:
  - Cost analysis for `running` and `stopped` states.
  - Total cost calculation from instance creation date.

### 3. `manage_instances`
- **Description**: Manages EC2 instances by allowing users to stop or terminate them. (The option to start instances is still in development.)
- **Features**:
  - Stop instances.
  - Terminate instances.
  - *Pending*: Start instances functionality.

