// SPDX-License-Identifier: MIT LICENSE



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


pragma solidity ^0.8.18;

contract GSReserves is Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

//State variable to track the current Reserve Vault ID
    uint256 public currentReserveId;

// Define a struct to represent a reserve vault

    struct ReserveVault {
        IERC20 collateral; // The ERC20 token used as collateral in this vault
        uint256 amount;  // The amount of collateral held in this vault
    }

    mapping(uint256 => ReserveVault) public _rsvVault;

// Events to log deposit and withdrawal actions
    event Withdraw (uint256 indexed vid, uint256 amount);
    event Deposit (uint256 indexed vid, uint256 amount);

 // Role definition for access control
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

// Constructor to set up roles and permissions
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

// Internal function to check if a given ERC20 token is already associated with a reserve vault
    function checkReserveContract(IERC20 _collateral) internal view {
        for(uint256 i; i < currentReserveId; i++){
            require(_rsvVault[i].collateral != _collateral, "Collateral Address Already Added");
        }
    }

  
 // External function to add a new reserve vault
    function addReserveVault(IERC20 _collateral) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not allowed");
        checkReserveContract(_collateral);
        _rsvVault[currentReserveId].collateral = _collateral;
        currentReserveId++;
    }

//depost the collateral as ERC-20 token
    function depositCollateral(uint256 _vid, uint256 _amount) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not allowed");
        IERC20 reserves = _rsvVault[_vid].collateral;
        reserves.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 currentVaultBalance = _rsvVault[_vid].amount;
        _rsvVault[_vid].amount = currentVaultBalance.add(_amount);
        emit Deposit(_vid, _amount);
    }

    function withdrawCollateral(uint256 _vid, uint256 _amount) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not allowed");
        IERC20 reserves = _rsvVault[_vid].collateral;
        uint256 currentVaultBalance = _rsvVault[_vid].amount;
        if (currentVaultBalance >= _amount) {
            reserves.safeTransfer(address(msg.sender), _amount);
        }
            _rsvVault[_vid].amount = currentVaultBalance.sub(_amount);
            emit Withdraw(_vid, _amount);
        }
    }
  function reserveLength() external view returns (uint256) {
    return currentReserveId;
}

}