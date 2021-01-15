// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../implementations/vault/VaultBaseline.sol";

contract VaultBaselinewETH is VaultBaseline {
    constructor()
        public
        VaultBaseline(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
            address(0xDc03b4900Eff97d997f4B828ae0a45cd48C3b22d)
        )
    {}
}
