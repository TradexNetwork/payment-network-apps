pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./KeycardWallet.sol";
import "./KeycardRegistry.sol";

contract KeycardWalletFactory is KeycardRegistry {
  mapping(address => address[]) public ownersWallets;
  mapping(address => address) public keycardsWallets;
  address public currency;
  address public blockRelay;
  address public owner;

  event NewWallet(KeycardWallet wallet);

  function init(address _currency, address _blockRelay) public {
    require(owner == address(0), "this function can only be invoked once");

    owner = msg.sender;
    currency = _currency;
    blockRelay = _blockRelay;
  }

  function create(address _keycard, bool _keycardIsOwner, uint256 _minBlockDistance, uint256 _txMaxAmount) public {
    address owner = _keycardIsOwner ? _keycard : msg.sender;

    require(keycardsWallets[_keycard] == address(0), "the keycard is already associated to a wallet");

    KeycardWallet wallet = new KeycardWallet();
    ownersWallets[owner].push(address(wallet));
    keycardsWallets[_keycard] = address(wallet);
    wallet.init(owner, _keycard, address(this), blockRelay, _minBlockDistance, currency, _txMaxAmount);
    emit NewWallet(wallet);
  }

  function addressFind(address[] storage _arr, address _a) internal view returns (uint) {
    for (uint i = 0; i < _arr.length; i++){
      if (_arr[i] == _a) {
        return i;
      }
    }

    revert("address not found");
  }

  function addressDelete(address[] storage _arr, uint _idx) internal {
    _arr[_idx] = _arr[_arr.length-1];
    _arr.length--;
  }

  function setOwner(address _oldOwner, address _newOwner) public {
    uint idx = addressFind(ownersWallets[_oldOwner], msg.sender);
    ownersWallets[_newOwner].push(ownersWallets[_oldOwner][idx]);
    addressDelete(ownersWallets[_oldOwner], idx);
  }

  function setKeycard(address _oldKeycard, address _newKeycard) public {
    address wallet = keycardsWallets[_oldKeycard];

    require(wallet == msg.sender, "only the registered wallet can call this");
    require(keycardsWallets[_newKeycard] == address(0), "the keycard already has a wallet");

    keycardsWallets[_newKeycard] = wallet;
    delete keycardsWallets[_oldKeycard];
  }

  function unregisterFromOwner(address _wallet, address _keycard) public {
    uint idx = addressFind(ownersWallets[msg.sender], _wallet);

    require(_wallet == keycardsWallets[_keycard], "owner required");

    addressDelete(ownersWallets[msg.sender], idx);
    delete keycardsWallets[_keycard];
  }

  function countWalletsForOwner(address owner) public view returns (uint) {
    return ownersWallets[owner].length;
  }

  function unregister(address _owner, address _keycard) public {
    uint idx = addressFind(ownersWallets[_owner], msg.sender);

    require(ownersWallets[_owner][idx] == keycardsWallets[_keycard], "only the associated keycard can be deassociated");

    addressDelete(ownersWallets[_owner], idx);
    delete keycardsWallets[_keycard];
  }

  function register(address _owner, address _keycard) public {
    require(keycardsWallets[_keycard] == address(0), "the keycard already has a wallet");

    ownersWallets[_owner].push(msg.sender);
    keycardsWallets[_keycard] = msg.sender;
  }
}
