// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { ERC1155 } from '@solidstate/contracts/token/ERC1155/ERC1155.sol';
import { IERC1155 } from '@solidstate/contracts/token/ERC1155/IERC1155.sol';
import { ERC165Storage } from '@solidstate/contracts/introspection/ERC165Storage.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { WrapperStorage } from '../libraries/WrapperStorage.sol';

contract MySet is ERC1155 {
    using ERC165Storage for ERC165Storage.Layout;

    constructor() {
        ERC165Storage.layout().setSupportedInterface(
            type(IERC1155).interfaceId,
            true
        );
    }

    function initERC1155() public {
        WrapperStorage.Layout storage l = WrapperStorage.layout();
        // initialize Ether at id1
        l.addressToID[address(0x1)] = 0x1;
        l.IDtoAddress[0x1] = address(0x1);
        l.nTokens = 1;
    }

    receive () external payable {
        // fallback - deposit Ether sent with transaction
        deposit(address(0x1), msg.sender, msg.value);
    }

    function deposit(address _token, address _recipient, uint256 _value)
        public payable
    {
        WrapperStorage.Layout storage l = WrapperStorage.layout();
        require(_recipient != address(0x0), "ERC20Wrapper#deposit: INVALID_RECIPIENT");

        // declare ID of deposited ERC20
        uint256 id;

        // deposit the ERC20 or Ether
        if (_token != address(0x1)) {

        // check if transfer passes
        require(msg.value == 0, "ERC20Wrapper#deposit: NON_NULL_MSG_VALUE");
        IERC20(_token).transferFrom(msg.sender, address(this), _value);
          require(checkSuccess(), "ERC20Wrapper#deposit: TRANSFER_FAILED");

        // load address's ID
        uint256 addressId = l.addressToID[_token];

        // register ID if not already in use
        if (addressId == 0) {
            l.nTokens += 1;                 // increment number of tokens registered
            id = l.nTokens;                 // ID of token is the current # of tokens
            l.IDtoAddress[id] = _token;   // map ID to token address
            l.addressToID[_token] = id;   // register token

        } else {
            id = addressId;
        }

        } else {
        require(_value == msg.value, "ERC20Wrapper#deposit: INCORRECT_MSG_VALUE");
        id = 0x1;
        }

        // mint 1155 tokens
        _mint(_recipient, id, _value, "");
    }

    function withdraw(address _token, address payable _to, uint256 _value) public {
        uint256 tokenID = getTokenID(_token);
        _withdraw(msg.sender, _to, tokenID, _value);
    }

    function _withdraw(
        address _from,
        address payable _to,
        uint256 _tokenID,
        uint256 _value)
        internal
    {
        WrapperStorage.Layout storage l = WrapperStorage.layout();

        // burn 1155 tokens
        _burn(_from, _tokenID, _value);

        // withdraw ERC20 tokens or Ether
        if (_tokenID != 0x1) {
        address token = l.IDtoAddress[_tokenID];
        IERC20(token).transfer(_to, _value);
        require(checkSuccess(), "ERC20Wrapper#withdraw: TRANSFER_FAILED");

        } else {
        require(_to != address(0), "ERC20Wrapper#withdraw: INVALID_RECIPIENT");
        (bool success, ) = _to.call{value: _value}("");
        require(success, "ERC20Wrapper#withdraw: TRANSFER_FAILED");
        }
    }

    function getTokenID(address _token) public view returns (uint256 tokenID) {
        WrapperStorage.Layout storage l = WrapperStorage.layout();
        tokenID = l.addressToID[_token];
        require(tokenID != 0, "ERC20Wrapper#getTokenID: UNREGISTERED_TOKEN");
        return tokenID;
    }

    function getIdAddress(uint256 _id) public view returns (address token) {
        WrapperStorage.Layout storage l = WrapperStorage.layout();
        token = l.IDtoAddress[_id];
        require(token != address(0x0), "ERC20Wrapper#getIdAddress: UNREGISTERED_TOKEN");
        return token;
    }

    function getNTokens() external view returns (uint256) {
        WrapperStorage.Layout storage l = WrapperStorage.layout();
        return l.nTokens;
    }

    function __mint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _mint(account, id, amount, '');
    }

    function __burn(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _burn(account, id, amount);
    }

    function checkSuccess()
        private pure
        returns (bool)
    {
        uint256 returnValue = 0;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
        // check number of bytes returned from last function call
        switch returndatasize()

            // no bytes returned: assume success
            case 0x0 {
            returnValue := 1
            }

            // 32 bytes returned: check if non-zero
            case 0x20 {
            // copy 32 bytes into scratch space
            returndatacopy(0x0, 0x0, 0x20)

            // load those bytes into returnValue
            returnValue := mload(0x0)
            }

            // not sure what was returned: dont mark as success
            default { }
        
        }

        return returnValue != 0;
    }
}