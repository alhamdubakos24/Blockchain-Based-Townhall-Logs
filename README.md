# 🏛️ Blockchain-Based Townhall Logs

A Clarity smart contract for storing immutable records of local government meetings and decisions on the Stacks blockchain.

## 📋 Overview

This smart contract provides a transparent, immutable system for recording:
- 📅 Meeting records with complete metadata
- 🗳️ Decision voting and outcomes
- 👥 Participant attendance tracking
- 🔐 Role-based access control

## ✨ Features

- **Immutable Records**: All meetings and decisions are permanently stored on-chain
- **Authorized Officials**: Only authorized government officials can create records
- **Voting System**: Complete voting functionality with vote counting
- **Attendance Tracking**: Record who attended meetings and their roles
- **Public Access**: Anyone can read meeting records and decisions
- **Admin Controls**: Contract admin can authorize/revoke officials

## 🚀 Getting Started

### Prerequisites

- Clarinet installed
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `clarinet check` to verify the contract

## 📖 Usage

### Core Functions

#### 🏛️ Meeting Management

**Create a Meeting Record**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs create-meeting-record
    u"Town Budget Meeting"
    u20240315
    u"City Hall"
    (list 'SP1ABC... 'SP2DEF...)
    u"Discuss 2024 budget proposals"
    u"Meeting concluded with budget approval")
```

**Update Meeting Minutes**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs update-meeting-minutes
    u1
    u"Updated minutes with final vote counts")
```

**Close Meeting**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs close-meeting u1)
```

#### 🗳️ Decision Management

**Create Decision Record**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs create-decision-record
    u1
    u"Budget Approval"
    u"Approve 2024 municipal budget of $2.5M"
    u20240315)
```

**Cast Vote**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs cast-vote u1 "for")
```

**Finalize Decision**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs finalize-decision u1 "approved")
```

#### 👥 Access Control

**Authorize Official**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs authorize-official 'SP1ABC...)
```

**Revoke Official**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs revoke-official 'SP1ABC...)
```

### 📊 Read-Only Functions

**Get Meeting Record**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs get-meeting-record u1)
```

**Get Decision Record**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs get-decision-record u1)
```

**Get Vote Summary**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs get-vote-summary u1)
```

**Check Authorization**
```clarity
(contract-call? .Blockchain-Based-Townhall-Logs is-authorized-official 'SP1ABC...)
```

## 🔧 Testing

Run the test suite:
```bash
clarinet test
```

## 🏗️ Data Structures

### Meeting Records
- Title, date, location
- Organizer and participants
- Agenda and minutes
- Status and block height

### Decision Records
- Meeting ID reference
- Title and description
- Vote counts (for/against/abstain)
- Status and timestamps

### Attendance Records
- Meeting and participant mapping
- Attendance status and role

## 🛡️ Security Features

- **Authorization**: Only authorized officials can create records
- **Immutability**: Records cannot be deleted once created
- **Transparency**: All data is publicly readable
- **Vote Integrity**: One vote per official per decision

## 🌐 Deployment

Deploy to Stacks testnet:
```bash
clarinet deploy --testnet
```

## 📄 Contract Address

The contract will be deployed at: `{deployer-address}.Blockchain-Based-Townhall-Logs`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📜 License

This project is open source and available under the MIT License.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

---

*Built with ❤️ for transparent governance*
