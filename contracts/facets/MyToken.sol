// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';
import { ERC1155EnumerableStorage } from '@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

contract MyToken is ERC20 {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;
    using ERC1155EnumerableStorage for ERC1155EnumerableStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyComptroller (address comptroller) {
        require(comptroller != address(0), "Not valid address");
        ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage.layout();
        require(EnumerableSet.contains(l.accountsByToken[0x99], comptroller) == true, "Not comptroller");
        _;
    }

    function getRoleSupply(uint256 id) external view returns (uint256) {
        ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage.layout();
        return l.totalSupply[id];
    }

    function verifyRole(uint256 roleID, address account) external view returns (bool hasRole) {
        ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage.layout();
        return EnumerableSet.contains(l.accountsByToken[roleID], account);
    }

    function initERC20(string calldata name, string calldata symbol, uint8 decimals, uint256 supply) public {
        ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();

        l.setName(name);
        l.setSymbol(symbol);
        l.setDecimals(decimals);

        _mint(msg.sender, supply);
    }

    function __burn(
        address dao,
        uint256 amount
    ) external onlyComptroller(msg.sender) {
        _burn(dao, amount);
    }
}