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

    //Evento de compra de tokens
    event ComprandoTokens(uint,address);

    constructor() public {
        token = new ERC20Basic(tokens_creados);
        owner = msg.sender;
        contrato = address(this);
    }

    // ----------------------------------------- TOKEN --------------------------------

    //Funcion que estable el precio de los token en ether
    function PrecioToken(uint _numTokens) internal pure returns(uint){
        return _numTokens*(0.001 ether);
    }

    //Funcion para generar mas Tokens para la loteria
    function GenerarTokens(uint _numTokens) public Unicamente(owner){
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
        //Emitir el evento de compra tokens
        emit ComprandoTokens(_numTokens, msg.sender);
    }

    //Balance de tokens en el contrato de loteria
    function TokensDisponibles() public view returns(uint){
        return token.balanceOf(contrato);
    }

    //Obtener el balance de tokens acumulados en el pozo
    function Pozo() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Balance de tokens de una persona
    function Mistokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    // ------------------------------------- LOTERIA -------------------------
    
    //Precio del boleto de loteria
    uint public PrecioBoleto = 5;
    //Relacion entre la persona que compra boletos y los numeros de los boletos
    mapping (address => uint[]) idPersona_boletos;
    //Relacion necesario para identificar el ganador
    mapping(uint => address) ADN_boleto;
    //Numero aleatorio
    uint randNonce = 0;
    //Boletos generados
    uint[] boletos_comprados;

    //Eventos
    //Evento cuando se compra un boleto
    event boleto_comprado(uint, address);
    // Evento del ganador
    event boleto_ganador(uint);
    //Evento para devolver tokens
    event tokens_devueltos(uint, address);

    //Funcion para comprar boletos de loteria
    function CompraBoleto(uint _boletos) public{
        //Precio total de los boletos a comprar
        uint precio_total = _boletos * PrecioBoleto;
        //Filtrado de los tokens a pagar
        require(precio_total <= Mistokens(), "Necesitas comprar mas tokens.");
        //Transferencia de tokens al owner
        /* El cliente paga la atraccion en Tokens:
        -Ha sido necesario crear una funcion en ERC20.sol con el nombre: "transfer_loteria"
        debido a que en caso de usar la Transfer o TransferFrom las direcciones que se usaban 
        para realizar la transaccion eran erroneas. Ya que el msg.sender que recibia el metodo
        era la direccion del propio contrato
        */
        token.transfer_loteria(msg.sender, owner, precio_total);

        for(uint i = 0; i < _boletos; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;
            randNonce++;
            //Almacenamos los datos de los boletos
            idPersona_boletos[msg.sender].push(random);
            //Numero de boleto comprado
            boletos_comprados.push(random);
            //Asignacion del ADN del boleto para tener un ganador (ESTO ESTA BIEN?)
            ADN_boleto[random] = msg.sender;
            //Emision del evento
            emit boleto_comprado(random, msg.sender);
        }
    }

    //Funcion para visualizar los numneros d eboletos de una persona
    function TusBoletos() public view returns(uint [] memory){
        return idPersona_boletos[msg.sender];
    }

    //Funcion para generar un ganador y transferirle los tokens
    function GenerarGanador() public Unicamente(msg.sender){
        //Debe haber boletos comprados para generar un ganador
        require(boletos_comprados.length > 0, "Todavia no se compro ningun boleto");
        //Declaracion de la longitud del array
        uint longitud = boletos_comprados.length;
        //Aleatoriamente elijo un numero entre 0 - Longitud
        uint posicion_array = uint (uint(keccak256(abi.encodePacked(block.timestamp))) % longitud);
        //Seleccion del numero aleatorio mediante la posicion del array aleatoria
        uint eleccion = boletos_comprados[posicion_array];
        //Emitir el evento del ganador
        emit boleto_ganador(eleccion);
        //Recuperar la direccion del ganador
        address direccion_ganador = ADN_boleto[eleccion];
        // Enviarle los tokens del premio al ganador
        token.transfer_loteria(msg.sender, direccion_ganador, Pozo());
    }

    //Devolucion de los tokens
    function DevolverTokens(uint _numTokens) public payable{
        //El numero de tokens a devolver debe ser mayor a 0
        require(_numTokens > 0, "Necesitas devolver un numero positivo de tokens.");
        //El usuario debe tener los tokens a devolver
        require(_numTokens <= Mistokens(), "No tienes los tokens que deseas devolver.");
        /*DEVOLUCION:
         1.- El cliente devuelve tokens
         2.- La loteria paga los tokens devueltos
        */
        token.transfer_loteria(msg.sender, address(this), _numTokens);
        payable(msg.sender).transfer(PrecioToken(_numTokens));
        //Emision del evento
        emit tokens_devueltos(_numTokens, msg.sender);
    }

}