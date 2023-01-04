// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.9.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";


contract Loteria{

    //Instancia del contrato Token
    ERC20Basic private token;

    //Direcciones
    address public owner;
    address public contrato;

    //Numero de tokens a crear
    uint public tokens_creados = 10000;

    constructor() public {
        token = new ERC20Basic(tokens_creados);
        owner = msg.sender;
        contrato = address(this);
    }

}