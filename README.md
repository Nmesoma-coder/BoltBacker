# BoltBacker

**Decentralized crowdfunding platform for innovative projects with milestone-based funding**

VisionVault is a revolutionary blockchain-based crowdfunding platform that empowers visionaries to launch innovative projects while providing investors with transparent, milestone-driven funding mechanisms. Built on the Stacks blockchain using Clarity smart contracts, VisionVault ensures trust, transparency, and accountability in every funding campaign.

## ✨ Features

### 🚀 For Visionaries (Project Creators)
- **Launch Innovation Projects**: Create compelling funding campaigns with detailed descriptions and milestone roadmaps
- **Milestone-Based Funding**: Define up to 5 key milestones with specific treasury allocations
- **Complete Control**: Manage your project timeline and mark milestones as achieved
- **Success Tracking**: Monitor funding progress and investor engagement in real-time

### 💰 For Investors
- **Transparent Investment**: Back projects with clear milestone visibility and fund allocation
- **Risk Protection**: Automatic refund eligibility for failed campaigns
- **Portfolio Tracking**: Monitor your investments across multiple innovation projects
- **Community Driven**: Support breakthrough ideas and innovative solutions

### 🔒 Platform Security
- **Smart Contract Powered**: All transactions secured by Clarity smart contracts
- **Automated Refunds**: Built-in protection for investors when projects fail to meet targets
- **Milestone Verification**: Transparent progress tracking with immutable achievement records
- **Decentralized Governance**: Community-driven platform with minimal central authority

## 🏗️ Smart Contract Architecture

### Core Data Structures

#### Innovation Projects
```clarity
{
  visionary: principal,           // Project creator
  title: string-utf8,            // Project name
  description: string-utf8,      // Detailed description
  target-treasury: uint,         // Funding goal
  raised-treasury: uint,         // Current funds raised
  deadline-block: uint,          // Campaign end block
  is-active: bool,              // Campaign status
  is-completed: bool,           // Project completion status
  milestones: list              // Achievement roadmap
}
```

#### Project Investors
```clarity
{
  investment-amount: uint,       // Total invested amount
  refund-claimed: bool          // Refund status
}
```

## 🎯 Key Functions

### Project Management
- `launch-project`: Create new innovation campaigns
- `invest-in-project`: Back promising projects with STX
- `achieve-milestone`: Mark project milestones as completed
- `complete-project`: Finalize successful projects

### Investor Protection
- `claim-refund`: Recover investments from failed projects
- `close-failed-project`: Trigger refund eligibility for unsuccessful campaigns

## 🚀 Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarinet for local testing
- STX tokens for transactions

### Deployment
1. Clone the repository
2. Install Clarinet: `npm install -g @stacks/clarinet`
3. Test locally: `clarinet test`
4. Deploy to testnet: `clarinet deploy --testnet`

### Usage Example

#### Launch a Project
```clarity
(launch-project 
  "Revolutionary AI Platform"
  "Building the next generation of decentralized AI infrastructure"
  u1000000  ;; 1M microSTX target
  u100000   ;; Deadline in blocks
  (list 
    { description: "MVP Development", treasury-allocation: u300000 }
    { description: "Beta Testing", treasury-allocation: u200000 }
    { description: "Launch Preparation", treasury-allocation: u500000 }
  )
)
```

#### Invest in a Project
```clarity
(invest-in-project u1 u50000)  ;; Invest 50k microSTX in project #1
```

## 🛡️ Security Features

- **Input Validation**: Comprehensive parameter checking for all functions
- **Access Control**: Role-based permissions for project management
- **Error Handling**: Detailed error codes for debugging and user feedback
- **Refund Protection**: Automated investor protection mechanisms

## 🌟 Why VisionVault?

1. **Innovation First**: Designed specifically for breakthrough projects and cutting-edge ideas
2. **Investor Confidence**: Built-in refund mechanisms reduce investment risk
3. **Transparent Progress**: Milestone-based funding ensures accountability
4. **Decentralized Trust**: Blockchain-powered transparency eliminates intermediaries
5. **Community Driven**: Platform governance by the community, for the community

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | UNAUTHORIZED-ACCESS | User lacks required permissions |
| 101 | INSUFFICIENT-TREASURY | Treasury allocation exceeds target |
| 102 | PROJECT-NOT-FOUND | Invalid project ID |
| 103 | CAMPAIGN-INACTIVE | Project is closed or expired |
| 104 | MILESTONE-ALREADY-ACHIEVED | Milestone already completed |
| 105 | INVALID-MILESTONE-ID | Milestone index out of bounds |
| 106 | NO-REFUND-AVAILABLE | No investment to refund |
| 107 | REFUND-ALREADY-CLAIMED | Refund previously processed |
| 108 | PROJECT-SUCCESSFULLY-FUNDED | Project met funding goals |
| 109 | INVALID-PARAMETERS | Invalid function parameters |
| 110 | MILESTONES-INCOMPLETE | All milestones must be achieved |

## 🤝 Contributing

We welcome contributions from the community! Please read our contributing guidelines and submit pull requests for any improvements.

## 📄 License

This project is licensed under the MIT Licens.