// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationalBonds {
    address public owner;
    uint256 public bondIdCounter;

    struct Bond {
        uint256 id;
        address institution;
        uint256 amount;
        uint256 maturityDate;
        uint256 interestRate;
        bool repaid;
    }

    mapping(uint256 => Bond) public bonds;
    mapping(address => uint256) public institutionBalance;

    event BondIssued(uint256 bondId, address institution, uint256 amount, uint256 maturityDate, uint256 interestRate);
    event BondRepaid(uint256 bondId, address institution, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyInstitution() {
        require(institutionBalance[msg.sender] > 0, "Not an authorized institution");
        _;
    }

    function authorizeInstitution(address _institution) external onlyOwner {
        institutionBalance[_institution] = 1; // Placeholder for authorization logic
    }

    function deauthorizeInstitution(address _institution) external onlyOwner {
        institutionBalance[_institution] = 0; // Placeholder for deauthorization logic
    }

    function issueBond(address _institution, uint256 _amount, uint256 _maturityDate, uint256 _interestRate) external onlyOwner {
        require(institutionBalance[_institution] > 0, "Institution not authorized");
        require(_amount > 0, "Amount must be greater than zero");
        require(_maturityDate > block.timestamp, "Maturity date must be in the future");

        bondIdCounter++;
        bonds[bondIdCounter] = Bond({
            id: bondIdCounter,
            institution: _institution,
            amount: _amount,
            maturityDate: _maturityDate,
            interestRate: _interestRate,
            repaid: false
        });

        emit BondIssued(bondIdCounter, _institution, _amount, _maturityDate, _interestRate);
    }

    function repayBond(uint256 _bondId) external payable onlyInstitution {
        Bond storage bond = bonds[_bondId];
        require(bond.institution == msg.sender, "Not the bond issuer");
        require(!bond.repaid, "Bond already repaid");
        require(msg.value >= bond.amount, "Insufficient payment");

        uint256 totalRepayment = bond.amount + (bond.amount * bond.interestRate / 100);
        require(msg.value >= totalRepayment, "Insufficient payment for full repayment");

        bond.repaid = true;
        payable(owner).transfer(totalRepayment); // Transfer repayment to the owner
        
        emit BondRepaid(_bondId, msg.sender, totalRepayment);
    }

    // Function to withdraw any accidentally sent Ether to the contract
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
