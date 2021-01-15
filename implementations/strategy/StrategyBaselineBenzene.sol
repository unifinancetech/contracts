// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../interfaces/unifinancetech/Controller.sol";
import "../../interfaces/unifinancetech/Vault.sol";

import "./StrategyBaseline.sol";

abstract contract StrategyBaselineBenzene is StrategyBaseline {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public recv;
    address public fwant;
    address public frecv;

    constructor(address _want, address _controller)
        public
        StrategyBaseline(_want, _controller)
    {}

    function DepositToken(uint256 _amount) internal virtual;

    function WithdrawToken(uint256 _amount) internal virtual;

    function GetPriceE18OfRecvInWant() public virtual view returns (uint256);

    function SetRecv(address _recv) internal {
        recv = _recv;
        frecv = Controller(controller).vaults(recv);
        fwant = Controller(controller).vaults(want);
        require(recv != address(0), "!recv");
        require(fwant != address(0), "!fwant");
        require(frecv != address(0), "!frecv");
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            DepositToken(_want);
        }
        uint256 _recv = IERC20(recv).balanceOf(address(this));
        if (_recv > 0) {
            IERC20(recv).safeApprove(frecv, 0);
            IERC20(recv).safeApprove(frecv, _recv);
            Vault(frecv).deposit(_recv);
        }
    }

    function withdraw(IERC20 _asset)
        external
        override
        returns (uint256 balance)
    {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(recv != address(_asset), "recv");
        require(frecv != address(_asset), "frecv");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function withdraw(uint256 _aw) external override {
        require(msg.sender == controller, "!controller");
        uint256 _w = IERC20(want).balanceOf(address(this));
        if (_w < _aw) {
            uint256 _ar = _aw.sub(_w).mul(1e18).div(GetPriceE18OfRecvInWant());
            uint256 _r = IERC20(recv).balanceOf(address(this));
            if (_r < _ar) {
                uint256 _af = _ar.sub(_r).mul(1e18).div(
                    Vault(frecv).priceE18()
                );
                uint256 _f = IERC20(frecv).balanceOf(address(this));
                Vault(frecv).withdraw(Math.min(_f, _af));
            }
            _r = IERC20(recv).balanceOf(address(this));
            WithdrawToken(Math.min(_r, _ar));
        }
        _w = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(fwant, Math.min(_aw, _w));
    }

    function withdrawAll() external override returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        uint256 _frecv = IERC20(frecv).balanceOf(address(this));
        if (_frecv > 0) {
            Vault(frecv).withdraw(_frecv);
        }
        uint256 _recv = IERC20(recv).balanceOf(address(this));
        if (_recv > 0) {
            WithdrawToken(_recv);
        }
        balance = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(fwant, balance);
    }

    function balanceOf() public override view returns (uint256) {
        uint256 _frecv = IERC20(frecv).balanceOf(address(this));
        uint256 _recv = IERC20(recv).balanceOf(address(this));
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_frecv > 0) {
            _frecv = Vault(frecv).priceE18().mul(_frecv).div(1e18);
            _recv = _recv.add(_frecv);
        }
        if (_recv > 0) {
            _recv = GetPriceE18OfRecvInWant().mul(_recv).div(1e18);
            _want = _want.add(_recv);
        }
        return _want;
    }
}
