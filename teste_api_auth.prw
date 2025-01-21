#INCLUDE "TOTVS.CH"
#Include "Protheus.ch"

/*
Fun��o para valida��o do header de autentica��o Basic customizada
@type function
@version 1.0
@author Anderson Navarro
@since 20/01/2025
@param cAuthBasic, string, Header de autentica��o Basic
@param cError, string, Vari�vel para retorno de erro
@return logical, Indica se a autentica��o � v�lida
*/
User Function ValidaAuth(cAuthBasic, cError)
    Local lRet := .F.
    Local cUserPass := ""
    Local aUserPass := {}
    
    // Valida��o do header Basic
    If Empty(cAuthBasic)
        cError := "Header de autentica��o n�o informado"
        Return .F.
    EndIf
    
     
    cAuthBasic := StrTran(cAuthBasic, "Basic ", "")
    cUserPass := Decode64(cAuthBasic)
    aUserPass := StrTokArr(cUserPass, ":")
    
    If Len(aUserPass) != 2
        cError := "Formato de autentica��o inv�lido"
        Return .F.
    EndIf
    
    // Aqui irei deixar um usu�rio e senha padr�o, mas podemos 
    // substituir por uma vari�vel de ambiente, banco de dados (cadastro de usu�rio) ou defini��o por parametro.
    If aUserPass[1] == "user" .And. aUserPass[2] == "pass"
        lRet := .T.
    Else
        cError := "Usu�rio ou senha inv�lidos"
    EndIf
    
Return lRet
