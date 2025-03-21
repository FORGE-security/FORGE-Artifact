// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.6.10 <=0.8.10;
pragma experimental ABIEncoderV2;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface IAToken is IERC20Metadata, IScaledBalanceToken {
    function getIncentivesController()
        external
        view
        returns (IAaveIncentivesController);
}
