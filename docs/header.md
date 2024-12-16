# Materialize on Azure

Terraform module for deploying Materialize on Azure with all required infrastructure components.

This module sets up:
- AKS cluster for Materialize workloads
- Azure Database for PostgreSQL Flexible Server for metadata storage
- Azure Blob Storage for persistence
- Required networking and security configurations
- Managed identities with proper RBAC permissions

> **Warning** This is provided on a best-effort basis and Materialize cannot offer support for this module.

The module has been tested with:
- AKS version 1.28
- PostgreSQL 15
- Materialize Operator v0.1.0
