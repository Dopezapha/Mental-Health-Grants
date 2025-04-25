# Mental Health Support Network Smart Contract

## Overview
This smart contract facilitates the collection and distribution of donations to mental health initiatives on the Stacks blockchain. It provides a transparent, secure, and efficient way to manage contributions and support verified mental health service recipients.

## Features
- **Donation Management**: Secure collection of STX tokens from supporters
- **Recipient Verification**: Only authorized recipients can receive distributed funds
- **Transparent Distribution**: All aid distributions are recorded on-chain
- **Administrative Controls**: Governance mechanisms to ensure proper oversight
- **Crisis Mode**: Special operational state for emergency situations

## Core Components

### Roles
- **Supervisor**: The administrator who manages recipient enrollment, fund distribution, and system parameters
- **Supporters**: Individuals who donate STX to the support network
- **Recipients**: Verified mental health initiatives/individuals who receive aid

### Treasury
The contract maintains a central treasury where all donations are stored before distribution. The current balance is publicly viewable.

### Status Tracking
Recipients have status codes that indicate their current standing:
- `active`: Eligible to receive aid
- `pending`: Under review
- `suspended`: Temporarily ineligible
- `completed`: Has completed the program

## Contract Functions

### For Supporters

#### `provide-support()`
Allows anyone to donate STX to the network.
- Minimum contribution amount applies (default: 1 STX)
- Donation history is tracked per supporter

### For Recipients
Recipients don't directly interact with the contract. Their enrollment and aid distribution are managed by the supervisor.

### Administrative Functions

#### `enroll-recipient(recipient-address)`
Registers a new eligible recipient in the system.

#### `distribute-aid(recipient-address, aid-amount)`
Transfers the specified amount of STX from the treasury to a recipient.

#### `update-recipient-status(recipient-address, new-status)`
Updates a recipient's status (`active`, `pending`, `suspended`, or `completed`).

#### `set-contribution-floor(new-floor)`
Updates the minimum required donation amount.

#### `toggle-program-status()`
Enables or disables the entire program.

#### `set-crisis-mode-on()` / `set-crisis-mode-off()`
Activates or deactivates crisis mode, which restricts certain operations.

#### `change-supervisor(new-supervisor-address)`
Transfers administrative control to a new address.

### Read-Only Functions

#### `get-program-supervisor()`
Returns the current supervisor's address.

#### `get-treasury-balance()`
Returns the current balance of the treasury.

#### `get-recipient-info(recipient-address)`
Returns information about a specific recipient.

#### `get-supporter-info(supporter-address)`
Returns donation history for a specific supporter.

#### `check-program-status()`
Returns whether the program is currently operational.

## Error Codes

| Code | Description |
|------|-------------|
| 100 | Not authorized to perform this action |
| 101 | Recipient is already registered |
| 102 | Recipient is not registered |
| 103 | Insufficient funds in treasury |
| 104 | Contribution amount is below minimum |
| 105 | Program is currently paused |
| 106 | Invalid contribution amount |
| 107 | Invalid status code provided |
| 108 | Invalid supervisor address |

## Implementation Details

The contract is implemented in Clarity, the smart contract language for the Stacks blockchain. It leverages Clarity's:
- Principal types for secure address management
- Maps for efficient data storage
- Post-conditions for secure token transfers
- Read-only functions for transparent data access

## Security Considerations

- Only the designated supervisor can perform administrative actions
- Contribution limits prevent certain forms of abuse
- Crisis mode can be activated in emergency situations
- All financial transactions are recorded on-chain

## Getting Started

### Interacting with the Contract
The contract can be called using any Stacks wallet or development tool that supports contract calls. The most common interactions will be:

1. **For Supporters**:
   - Call `provide-support()` with your desired STX amount

2. **For Supervisors**:
   - Enroll recipients using `enroll-recipient()`
   - Distribute aid using `distribute-aid()`
   - Manage system parameters as needed