#include 'totvs.ch'
#include 'restful.ch'
  
#DEFINE LOG                       "\log_integ"
#DEFINE TIPO_REQUEST              "N"
#DEFINE PEDIDO_ABERTO             "pedido em aberto"
#DEFINE PEDIDO_ENCERRADO          "pedido encerrado"
#DEFINE PEDIDO_LIBERADO           "pedido liberado"
#DEFINE PEDIDO_BLOQ_REGRA         "pedido bloqueado por regra"
#DEFINE PEDIDO_BLOQ_VERBA         "pedido bloqueado por verba"
/*
API REST para consulta de status de pedidos de venda
Onde: Efetua a consulta na tabela SC5 e retorna o status do pedido de venda
@type class
@version 1.0
@author Anderson Navarro
@since 20/01/2025
/*/

WSRESTFUL WSPDVEND DESCRIPTION 'API de Consulta do Status de Pedidos de Venda' SECURITY 'MATA410' FORMAT APPLICATION_JSON
    
    WSDATA Requestinterprise as Character
    WSDATA RequestNumber As Character

    WSMETHOD GET StatusPedido DESCRIPTION 'Retorna o status do pedido de venda' WSSYNTAX '/?filial={Requestinterprise}&pedido={RequestNumber}' PRODUCES APPLICATION_JSON
ENDWSRESTFUL
/*
Método GET para consulta de status do pedido
@type function
@version 1.0
@author Anderson Navarro
@since 20/01/2025
@param id, string, ID do pedido de venda
@return object, json com status do pedido
/*/
WSMETHOD GET StatusPedido WSRECEIVE RequestNumber WSRESTFUL WSPDVEND
    Local lRet  := .T.
    Local cAliasSC5  := GetNextAlias()
    Local aData := {}
    Local oResponse := NIL

    Local cAuthBasic := Self:GetHeader("Authorization")
    Local lAuthorized := .F.
    Local cError := ""

    Private cRequestinterprise := SELF:AQUERYSTRING[1][2]
    Private cRequestNumber := SELF:AQUERYSTRING[2][2] 
  

    
    /* Anderson Navarro - 20/01/2025
    Validação de autenticação Basic:
    Função feita de forma isolada para reutilização da autenticação em outros fontes
    Caso o ambiente seja em T-Cloud, a autenticação é feita via OAuth com token no padrão,
    sem a ncessidade da autenticação abaixo.
    Também é possível utilizar a autenticação via OAuth no TOTVS Application Server alterando a chave no appserver.ini
    conforme documentação:
    https://centraldeatendimento.totvs.com/hc/pt-br/articles/14208936050711-Cross-Segmentos-Backoffice-Linha-Protheus-SIGAFIN-Valida%C3%A7%C3%A3o-REST-para-implanta%C3%A7%C3%A3o-APP-minha-presta%C3%A7%C3%A3o-de-contas#:~:text=A%20chave%20SECURITY%20indica%20se,chamada%20com%20o%20usu%C3%A1rio%20administrador.

    Chave = SECURITY

    Para demonstração do método, foi utilizado a chave SECURITY = 0 e a validação via rotina customizada
    */
    lAuthorized := U_ValidaAuth(cAuthBasic, @cError)
    
    If !lAuthorized
        SetRestFault(401, cError)
        Return .F.
    EndIf

    //Validação de parâmetros, obrigatorio informar o numero da filial e pedido
    IF Empty(cRequestinterprise) .and. Empty(cRequestNumber)
        SetRestFault(500,EncodeUTF8('O parametro filial e pedido são obrigatórios'))
        lRet    := .F.
        Return(lRet)
    EndIF
  
    /*
    montagem da consulta
    */
    BeginSQL Alias cAliasSC5
        SELECT SC5.C5_FILIAL
            ,SC5.C5_NUM
            ,SC5.C5_LIBEROK
            ,SC5.C5_NOTA
            ,SC5.C5_BLQ
        FROM %Table:SC5% SC5
        WHERE SC5.C5_FILIAL = %Exp:AllTrim(cRequestinterprise)%
            AND SC5.C5_NUM = %Exp:AllTrim(cRequestNumber)%
            AND SC5.%NotDel%
    EndSQL    
  
    
    dbSelectArea(cAliasSC5)
    (cAliasSC5)->(dbGoTop())
    IF (cAliasSC5)->(.NOT. Eof())
  
        //Enquanto houver dados na query
        While (cAliasSC5)->(.NOT. Eof())
  
            //Cria um objeto JSON
            oResponse:= JsonObject():New()
  
            //Efetua as validações do pedido de venda
            IF Empty((cAliasSC5)->C5_LIBEROK) .AND. Empty((cAliasSC5)->C5_NOTA) .AND. Empty((cAliasSC5)->C5_BLQ)
                oResponse['status'] := PEDIDO_ABERTO
            
            ELSEIF !Empty((cAliasSC5)->C5_NOTA) .OR. (cAliasSC5)->C5_LIBEROK=='E' .AND. Empty((cAliasSC5)->C5_BLQ)
                oResponse['status'] := PEDIDO_ENCERRADO
  
            ELSEIF !Empty((cAliasSC5)->C5_LIBEROK) .AND. Empty((cAliasSC5)->C5_NOTA) .AND. Empty((cAliasSC5)->C5_BLQ)
                oResponse['status'] := PEDIDO_LIBERADO  
  
            ELSEIF (cAliasSC5)->C5_BLQ=='1'
                oResponse['status'] := PEDIDO_BLOQ_REGRA
  
            ELSEIF (cAliasSC5)->C5_BLQ=='2'
                oResponse['status'] := PEDIDO_BLOQ_VERBA
            EndIF
  
            aAdd(aData,oResponse) //Adiciona o array ao objeto JSON
            FreeObj(oResponse)
  
            (cAliasSC5)->(dbSkip())
        EndDo
  
        //Define o retorno do método
        Self:SetResponse(FwJsonSerialize(aData))
  
    ELSE
        SetRestFault(500,EncodeUTF8('Não existem dados para serem apresentados'))
        lRet    := .F.
    EndIF    
  
    (cAliasSC5)->(dbCloseArea())
  
Return(lRet)
