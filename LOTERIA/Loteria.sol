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
    uint private tokens_creados = 10000;

    constructor() public {
        token = new ERC20Basic(tokens_creados);
        owner = msg.sender;
        contrato = address(this);
    }

    // ----------------------------------------- TOKEN --------------------------------

    //Funcion que estable el precio de los token en ether
    function PrecioToken(uint _numTokens) internal pure returns(uint){
        return _numTokens*(0.1 ether);
    }

    //Funcion para generar mas Tokens para la loteria
    function GenerarTokens(uint _numTokens) public Unicamente(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    modifier Unicamente(address _direccion){
        require(_direccion == owner, "No tienes permisos para ejecutar esta funcion.");
        _;
    }

    //Comprar tokens para comprar boletos de loteria
    function ComprarTokens(uint _numTokens) public payable{
        //Calcular el costo de los tokens
        uint costo = PrecioToken(_numTokens);
        //Requiere que el valor de ether pagado sea equivalente al costo
        require(msg.value >= costo,"Compra menos Tokens o paga con mas Ether");
        //Diferencia a pagar
        uint returnValue = msg.value - costo;
        //Transferencia de la diferencia
        payable(msg.sender).transfer(returnValue);
        //Obtener el balance de tokens del contrato
        uint balance = TokensDisponibles();
        //Filtro para evaluar los tokens a comprar con los tokens disponiblñes
        require(_numTokens <= balance,"Compra un numero de Tokens adecuado.");
        //Transferencia de Tokens al comprador
        token.transfer(msg.sender, _numTokens);
    }

    //Balance de tokens en el contrato de loteria
    function TokensDisponibles() public view returns(uint){
        return token.balanceOf(contrato);
    }

}