// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval( address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

contract NeoToken is IERC20 {
    string public constant name = "NEOTOKEN";
    string public constant symbol = "NEO";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 10000 * 10 ** decimals;
    // minimum required NEO tokens to creating proposal
    uint256 minReqToken = 1000 * 10 ** decimals;
    uint256 tokenAssigned = 10 * 10 ** decimals;
    address public admin;
    uint256 public proposalCount;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    using SafeMath for uint256;

    constructor() {
        admin = msg.sender;
        balances[msg.sender] = minReqToken;
        balances[0x152246AeFcCDbAC806B40af545A02818b8C5b48b] = tokenAssigned;
        balances[0xF3D68B7e53EF28763066C50B57eFc200C99EFB74] = tokenAssigned;
        balances[0x1176445983154b5863245916A4245fd84B720A96] = tokenAssigned;
        balances[0x64D73B0b84F0fE0a63dF9CA4A8bed8906a2fF06C] = tokenAssigned;

    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(amount <= balances[msg.sender],"transfer: Insufficient tokens to transfer");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(amount <= allowed[from][msg.sender],"transferFrom:Not Allowed to transfer");
        require(amount <= balances[from],"transferFrom:Insufficient tokens");

        balances[from] = balances[from].sub(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }
    /// @notice Detailed feilds of proposal
    struct Proposal {
        //  proposal Id
        uint256 id;
        //  owner of the proposal
        address proposer;
        //  favor votes of the proposal
        uint256 favorVotes;
        //  against votes of the proposal
        uint256 againstVotes;
        //  canceled = true if the proposal if cancelled
        bool canceled;
        //  announced = true if the proposal if announced
        bool announced;
        // total No.of voters
        uint256 voterCount;
        // description  of the proposal
        string description;
        // title  of the proposal
        string title;
        // proposal created Date
        uint256 dateOfCreation;
        // deadLine of the proposal for vote
        uint256 deadLine;
        // set the proposal is passed or rejected status by Enum
        ProposalState res;
    }
    /// @notice receipt record for a voters
    struct VoteReceipt {
        //  Whether Voted or Not
        bool isVoted;
        //  whether vote for favor or against
        bool isSupport;
        //  Vote Count
        uint256 votes;
    }

     struct Vote {
        address voterAddress;
        bool support;
        uint256 votes;
    }

    // The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    // To store receipts of all voters on all proposals
    // proposalId => (voterAddress => VoteReceipt)
    mapping(uint256 => mapping(address => VoteReceipt)) receipts;

    // To store all voters on all proposals
    // proposalId => (voterIndex => voterAddress)
    mapping(uint256 => mapping(uint256 => address)) voters;

    /// @notice Possible states that a proposal may be in
    enum ProposalState {ACTIVE, CANCELED, ACCEPTED, REJECTED}

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated( uint256 id, address proposer, string description, string title, uint256 dateOfCreation);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support);

    function createProposal(string memory proposalTitle, string memory proposalDescription) external onlyAdmin{
        require(
            balances[msg.sender] >= minReqToken,
            "createProposal: Must have more than 1000 NEO Token to create proposals"
        );
        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            favorVotes: 0,
            againstVotes: 0,
            canceled: false,
            announced: false,
            voterCount: 0,
            description: proposalDescription,
            title: proposalTitle,
            dateOfCreation: block.timestamp,
            deadLine: block.timestamp + 3 minutes,
            res: ProposalState.ACTIVE
        });

        proposals[newProposal.id] = newProposal;
        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            proposalDescription,
            proposalTitle,
            newProposal.dateOfCreation
        );
    }

    function getReceipt(uint256 proposalId, address voter) external view returns (VoteReceipt memory) {
        return receipts[proposalId][voter];
    }

    function stateOfTheProposal(uint256 proposalId) public returns (ProposalState) {
        uint256 totalAmountOfPassVoters;
        uint256 totalAmountOfRejectVoters;
        require(
            proposalCount >= proposalId && proposalId > 0,
            "state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.CANCELED;
        } else if (proposal.announced) {
            for (uint256 i = 0; i < proposal.voterCount; i++) {
                VoteReceipt storage receipt = receipts[proposalId][
                    voters[proposalId][i]
                ];
                if (receipt.isSupport == true) {
                    totalAmountOfPassVoters += balanceOf(voters[proposalId][i]);
                } else if (receipt.isSupport == false) {
                    totalAmountOfRejectVoters += balanceOf(voters[proposalId][i]);
                }
            }
            if (totalAmountOfPassVoters > totalAmountOfRejectVoters) {
                proposal.res = ProposalState.ACCEPTED;
                return ProposalState.ACCEPTED;
            } else {
                proposal.res = ProposalState.REJECTED;
                return ProposalState.REJECTED;
            }
        } else {
            return ProposalState.ACTIVE;
        }
    }

    function voteToProposal(uint256 proposalId, bool vote) external {
        require(
            proposalCount >= proposalId && proposalId > 0,
            "voteToProposal: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp <= proposal.deadLine,
            "voteToProposal: Voting period has ended"
        );
        require(
            balances[msg.sender] >= 0,
            "voteToProposal: User doesn't have sufficient token to vote"
        );
        VoteReceipt storage receipt = receipts[proposalId][msg.sender];
        require((receipt.isVoted == false), "voteToProposal: You can't vote again");

        receipt.isVoted = true;
        receipt.isSupport = vote;
        receipt.votes = 1;
        voters[proposalId][proposal.voterCount] = msg.sender;
        proposal.voterCount++;
        if (vote) {
            proposal.favorVotes = proposal.favorVotes.add(1);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }
        receipts[proposalId][msg.sender] = receipt;
        emit VoteCast(msg.sender, proposalId, vote);
    }

    function proposalResult(uint256 proposalId) external {
        require(proposalCount >= proposalId && proposalId > 0,"declareResult: invalid proposal id");

        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.deadLine,"declareResult: DeadLine has not yet passed");

        ProposalState _ProposalState = stateOfTheProposal(proposalId);
        require(_ProposalState != ProposalState.CANCELED, "declareResult: Prososal is canceled");
        require(
            _ProposalState != ProposalState.ACCEPTED &&_ProposalState != ProposalState.REJECTED,
            "declareResult: Result already announced"
        );
        proposal.announced = true;
    }

    function cancelProposal(uint256 proposalId) external {
        require(proposalCount >= proposalId && proposalId > 0, "cancelProposal: proposal id is invalid");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer,"cancelProposal: only admin can cancel the proposal");
        require(block.timestamp < proposal.deadLine,
            "cancelProposal: not able to cancel, DeadLine crossed"
        );
        ProposalState _ProposalState = stateOfTheProposal(proposalId);
        require(
            _ProposalState != ProposalState.CANCELED,
            "declareResult: Already in cancel state"
        );
        proposal.canceled = true;
    }

    function getVotes(uint256 proposalId) public view returns (Vote[] memory) {
        uint256 voterCount = proposals[proposalId].voterCount;
        Vote[] memory votes = new Vote[](voterCount);
        for (uint256 i = 0; i < voterCount; i++) {
            votes[i] = Vote(
                voters[proposalId][i],
                receipts[proposalId][voters[proposalId][i]].isSupport,
                receipts[proposalId][voters[proposalId][i]].votes
            );
        }
        return votes;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}