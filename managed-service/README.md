# Service Agreement Smart Contract

## About
A robust smart contract system built on Clarity for managing service agreements between service providers and clients. The contract facilitates the creation, management, and resolution of professional service agreements with built-in dispute resolution and provider rating mechanisms.

## Features
- Service Agreement Management
- Provider Rating System
- Dispute Resolution
- Provider Performance Metrics
- Secure Payment Handling
- Agreement Status Tracking

## Contract Structure

### Core Data Structures

#### ServiceAgreementDetails
```clarity
{
    service-provider-address: principal,
    client-address: principal,
    service-start-date: uint,
    service-end-date: uint,
    service-payment-amount: uint,
    agreement-status: string-ascii,
    service-description: string-ascii
}
```

#### ServiceProviderMetrics
```clarity
{
    provider-rating: uint,
    total-service-agreements: uint,
    successfully-completed-agreements: uint
}
```

#### ServiceDisputeRecords
```clarity
{
    dispute-initiator: principal,
    dispute-description: string-ascii,
    dispute-status: string-ascii,
    dispute-resolution: optional string-ascii
}
```

## Key Functions

### Agreement Management
- `create-service-agreement`: Create a new service agreement
- `accept-service-agreement`: Provider accepts a pending agreement
- `complete-service-agreement`: Mark agreement as completed

### Dispute Handling
- `file-service-dispute`: File a dispute for an agreement
- `resolve-service-dispute`: Resolve an existing dispute

### Provider Rating
- `submit-provider-rating`: Submit rating for a service provider

### Read-Only Functions
- `get-service-agreement-details`: Get agreement details
- `get-provider-metrics`: Get provider statistics
- `get-dispute-details`: Get dispute information

## Agreement Lifecycle
1. Creation (PENDING)
2. Acceptance (ACTIVE)
3. Completion (COMPLETED)
   - Optional: Dispute Resolution (DISPUTED)
   - Optional: Cancellation (CANCELLED)

## Error Codes
| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Agreement already exists |
| u102 | Agreement not found |
| u103 | Invalid agreement status |
| u104 | Insufficient payment |

## Security Considerations
- All functions include appropriate authorization checks
- Status transitions are strictly controlled
- Payment handling includes safety checks
- Dispute resolution limited to contract administrator
- Input validation for all critical parameters

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request