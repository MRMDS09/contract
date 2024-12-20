// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiPurposeContract {
    address public owner;
    uint256 public transactionFee; // نسبة الرسوم كنسبة مئوية (مثل 1 = 1%)
    uint256 public totalDonations;

    mapping(address => uint256) public balances; // رصيد كل مستخدم
    mapping(uint256 => Voting) public votings; // سجلات التصويت
    uint256 public votingCount;

    struct Voting {
        string description; // وصف القرار
        uint256 yesVotes;
        uint256 noVotes;
        bool active;
        mapping(address => bool) voters; // متابعة من قام بالتصويت
    }

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);
    event Donate(address indexed donor, uint256 amount);
    event Vote(uint256 votingId, address indexed voter, bool vote);
    event NewVoting(uint256 votingId, string description);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(uint256 _transactionFee) {
        owner = msg.sender;
        transactionFee = _transactionFee;
    }

    // إيداع الأموال
    function deposit() external payable {
        uint256 fee = (msg.value * transactionFee) / 100;
        uint256 amountAfterFee = msg.value - fee;

        balances[msg.sender] += amountAfterFee;
        emit Deposit(msg.sender, amountAfterFee);
    }

    // سحب الأموال
    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    // التبرع
    function donate() external payable {
        uint256 fee = (msg.value * transactionFee) / 100;
        uint256 amountAfterFee = msg.value - fee;

        totalDonations += amountAfterFee;
        emit Donate(msg.sender, amountAfterFee);
    }

    // إنشاء تصويت جديد
    function createVoting(string memory _description) external onlyOwner {
        Voting storage newVoting = votings[votingCount++];
        newVoting.description = _description;
        newVoting.active = true;

        emit NewVoting(votingCount - 1, _description);
    }

    // التصويت
    function vote(uint256 _votingId, bool _vote) external {
        Voting storage voting = votings[_votingId];
        require(voting.active, "Voting is not active");
        require(!voting.voters[msg.sender], "Already voted");

        voting.voters[msg.sender] = true;
        if (_vote) {
            voting.yesVotes++;
        } else {
            voting.noVotes++;
        }

        emit Vote(_votingId, msg.sender, _vote);
    }

    // إنهاء التصويت
    function endVoting(uint256 _votingId) external onlyOwner {
        Voting storage voting = votings[_votingId];
        require(voting.active, "Voting is already inactive");

        voting.active = false;
    }

    // تحديث الرسوم
    function updateTransactionFee(uint256 _newFee) external onlyOwner {
        transactionFee = _newFee;
    }
}
