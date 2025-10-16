# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-16

### Added
- Core round-robin assignment functionality
- Support for multiple independent assignment groups
- Dynamic assignee list handling
- Database persistence for assignment state
- Thread-safe operations via ActiveRecord transactions
- Statistics and monitoring via `group_stats` method
- Group reset functionality via `reset_group` method
- Rails generator for easy installation
- Comprehensive test suite with 100% coverage
- Full documentation and usage examples

### Features
- Persistent state tracking in database
- Graceful handling of removed assignees
- Automatic wrap-around when reaching end of list
- Support for any number of assignees
- ActiveRecord delegation for advanced queries
- Model validations for data integrity

## [Unreleased]

### Planned
- Weighted round-robin assignments
- Time-based restrictions (business hours, vacations)
- Assignment history tracking
- Web UI for management
- Webhook notifications
- Redis caching for high-volume systems
