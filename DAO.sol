pragma solidity 0.5.9;

contract DAO {
    
    uint public contributionEnd;
    uint public totalShares;
    uint public availableFunds;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public admin;
    
    struct Proposal {
        uint id;
        string name;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool executed;
    }
    
    mapping(address => bool) public investors;
    mapping(address => uint) public shares;
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) public votes;
    
    event Contributed(address _addr, uint _value);
    
    constructor(uint _contributionEnd) public {
        contributionEnd = now + _contributionEnd;
    }
    
    modifier onlyInvestors() {
        require(investors[msg.sender] == true, 'only investors can make this call');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin can make this call');
        _;
    }
    
    function contribute() payable external {
        require(now < contributionEnd, 'Contribution period already ended');
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
        emit Contributed(msg.sender, msg.value);
    }
    
    function redeemShares(uint amount) external onlyInvestors {
        require(shares[msg.sender] >= amount, 'Insufficient shares');
        require(availableFunds >= amount, 'Insufficient availableFunds');
        shares[msg.sender] -= amount;
        availableFunds -=amount;
        msg.sender.transfer(amount);
    }
    
    function transferShares(address to, uint amount) external {
        require(shares[msg.sender] >= amount, 'Insufficient shares');
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }
    
    function createProposal(string calldata name, uint amount, address payable recipient) external onlyInvestors {
        require(availableFunds >= amount, 'Not enough funds');
        proposals[nextProposalId] = Proposal(nextProposalId, name, amount, recipient, 0, now + voteTime, false);
        availableFunds -= amount;
        nextProposalId++;
    }
    
    function vote(uint proposalId) external onlyInvestors {
        Proposal memory proposal;
        proposals[proposalId] = proposal;
        require(votes[msg.sender][proposalId] == false, 'alreay voted');
        require(now < proposal.end, 'proposal already ended');
        votes[msg.sender][proposalId] = true;
        proposal.votes = shares[msg.sender];
    }
    
    function executeProposal(uint proposalId) external onlyAdmin {
        Proposal storage proposal = proposals[proposalId];
        require(now >= proposal.end, 'cannot execute before end');
        require(proposal.executed == false, 'cannot execute more than once');
        require((proposal.votes / totalShares) * 100 > quorum, 'cannot execute a proposal with votes below quorum');
        _transfer(proposal.amount, proposal.recipient);
    }
    
    function withrawEth(uint amount, address payable to) external onlyAdmin {
        _transfer(amount, to);
    }
    
    function _transfer(uint amount, address payable to) internal {
        require(availableFunds >= amount, 'insufficient fund');
        availableFunds -= amount;
        to.transfer(amount);
    }
    
    function() payable external {
        availableFunds += msg.value;
    }
}







