// SPDX-License-Identifier: MIT LICENSE



pragma solidity ^0.8.17.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SC.sol";
import "./GS.sol";

contract GsGovern is Ownable, ReentrancyGuard, AccessControl { 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SupChange {
        string method;
        uint256 amount;
        uint256 timestamp;
        uint256 blocknum;
    }

    struct ReserveList {
        IERC20 colToken;
    }


SC private sc; // Reference to the SC (Stable Coin) contract
GS private gs; // Reference to the GS (unstable collateral Token) contract
address private reserveContract; // Address of the contract responsible for handling reserves
uint256 public scsupply; // Total supply of the SC (Stable Coin) token
uint256 public gssupply; // Total supply of the GS (unstable collateral) token
address public datafeed; // Address of the external data feed contract
uint256 public supplyChangeCount; // Counter for tracking the number of supply changes
uint256 public stableColatPrice = 1e18; // Default price of stable collateral (scaled by 1e18)
uint256 public stableColatAmount; // Amount of stable collateral held in the contract
uint256 private constant COL_PRICE_TO_WEI = 1e10; // Scaling factor to convert collateral price to wei (10^10)
uint256 private constant WEI_VALUE = 1e18; // Scaling factor for wei value (10^18)
uint256 public unstableColatAmount; // Amount of unstable collateral held in the contract
uint256 public unstableColPrice; // Price of unstable collateral in wei
uint256 public reserveCount; // Counter for tracking the number of different reserve tokens


// Mapping to keep track of supply change events using their index
    mapping (uint256 => SupChange) public _supplyChanges;
    
    mapping (uint256 => ReserveList) public rsvList;

    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");

    event RepegAction(uint256 time, uint256 amount);
    event Withdraw(uint256 time, uint256 amount);

    constructor(SC _sc, GS _gs) {
        sc = _sc;
        gs = _gs;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERN_ROLE, _msgSender());
    }

    function addColateralToken(IERC20 colcontract) external nonReentrant {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        rsvList[reserveCount].colToken = colcontract;
        reserveCount++;
    }

    function setReserveContract(address reserve) external nonReentrant {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        reserveContract = reserve;
    }

    function setGsPrice(uint256 marketcap) external nonReentrant {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        gssupply = gs.totalSupply();
        unstableColPrice = ((marketcap).mul(gssupply)).div(WEI_VALUE);
    }


    function colateralReBalancing() internal returns (bool) {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        uint256 stableBalance = rsvList[0].colToken.balanceOf(reserveContract);
        uint256 unstableBalance = rsvList[1].colToken.balanceOf(reserveContract);
        if (stableBalance != stableColatAmount) {
            stableColatAmount = stableBalance;
        }
        if (unstableBalance != stableColatAmount) {
            unstableColatAmount = unstableBalance;
        }
        return true;
    }

    function setScSupply(uint256 totalSupply) external {
         require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
         scsupply = totalSupply;
    }

    function validatePeg() external nonReentrant {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        bool result = colateralReBalancing();
        if (result = true) {
            uint256 rawcolvalue = (stableColatAmount.mul(WEI_VALUE)).add(unstableColatAmount.mul(unstableColPrice));
            uint256 colvalue = rawcolvalue.div(WEI_VALUE);
            if (colvalue < scsupply) {
                uint256 supplyChange = scsupply.sub(colvalue);
                uint256 burnAmount = (supplyChange.div(unstableColPrice)).mul(WEI_VALUE);
                gs.burn(burnAmount);
                _supplyChanges[supplyChangeCount].method = "Burn";
                _supplyChanges[supplyChangeCount].amount = supplyChange;
            }
            if (colvalue > scsupply) {
                uint256 supplyChange = colvalue.sub(scsupply);
                sc.mint(supplyChange);
                _supplyChanges[supplyChangeCount].method = "Mint";
                _supplyChanges[supplyChangeCount].amount = supplyChange;
            }
        _supplyChanges[supplyChangeCount].blocknum = block.number;
        _supplyChanges[supplyChangeCount].timestamp = block.timestamp;
        supplyChangeCount++;
        emit RepegAction(block.timestamp, colvalue);
        }
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        sc.transfer(address(msg.sender), _amount);
        emit Withdraw(block.timestamp, _amount);
    }

    function withdrawGs(uint256 _amount) external nonReentrant {
        require(hasRole(GOVERN_ROLE, _msgSender()), "Not allowed");
        gs.transfer(address(msg.sender), _amount);
        emit Withdraw(block.timestamp, _amount);
    }


}
