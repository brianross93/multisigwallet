pragma solidity ^0.5.0;

contract MultiSignatureWallet {

    struct Transaction {
      bool executed;
      address destination;
      uint value;
      bytes data;
    }

    event Deposit(address indexed sender, uint value);
    event Submission(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionId)
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    
    address[] public owners;
        uint public required;
        mapping (address => bool) public isOwner;
    uint public transactionCount;
        mapping (uint => Transaction) public transactions;
    
    mapping (uint => mapping (address => bool)) public confirmations;
        
        
    

    /// @dev Fallback function allows to deposit ether.
    function()
    	external
        payable
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
	}
    }
    
                
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required) public 
                validRequirement(_owners.length, _required)
                {
                    for (uint i=0; i<_owners.length; i++) {
                        isOwner[_owners[i]] = true;
                    }
                    owners = _owners;
                    required = _required;
                    
                }
    
    modifier validRequirement(uint ownerCount, uint _required) {
        if ( _required > ownerCount || _required == 0 || ownerCount == 0 )
            revert();
        _;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data) public returns (uint transactionId) {
        //restricting function to only be callable by owner
        require(isOwner[msg.sender]);
        //this adds a transaction and confirms it using helper functions addTransaction and confirmTransaction
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {
        //only wallet owners should be able to call this
        require(isOwner[msg.sender]);
        //make sure transaction exists at specified id
        require(transactions[transactionId].destination != 0);
        //make sure transaction hasnt already been verified
        require(confirmations[transactionId][msg.sender] == false);
        //if everything is good we can set confirmations to true
        confirmations[transactionId][msg.sender] = true;
        //we are modifying state so we need to broadcast that
        emit Confirmation(msg.sender, transactionId);
        //then boom baby
        executeTransaction(transactionId);
        
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
        
        
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {
        //we make sure trnascation hasnt been executed
        require(transactions[transactionId].executed == false);
        if (isConfirmed(transactionId)) {
              Transaction storage t = transactions[transactionId];  // using the "storage" keyword makes "t" a pointer to storage 
              t.executed = true;
              (bool success, bytes memory returnedData) = t.destination.call.value(t.value)(t.data);
              if (success)
                  emit Execution(transactionId);
              else {
                  emit ExecutionFailure(transactionId);
                  t.executed = false;
              }
          }
  
        
    }

		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
          public
          view
          returns (bool)
      {
          uint count = 0;
          for (uint i=0; i<owners.length; i++) {
              if (confirmations[transactionId][owners[i]])
                  count += 1;
              if (count == required)
                  return true;
          }
      }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data) internal returns (uint transactionId) {
        
        // we get the transaction count, store the transactionId
        // and then increments the count. it changes state so we emit it
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    
        }
        )
    }
}
