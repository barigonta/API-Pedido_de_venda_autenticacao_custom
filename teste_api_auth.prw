#INCLUDE "TOTVS.CH"
#Include "Protheus.ch"

/*
Função para validação do header de autenticação Basic customizada
@type function
@version 1.0
@author Anderson Navarro
@since 20/01/2025
@param cAuthBasic, string, Header de autenticação Basic
@param cError, string, Variável para retorno de erro
@return logical, Indica se a autenticação é válida
*/
User Function ValidaAuth(cAuthBasic, cError)
    Local lRet := .F.
    Local cUserPass := ""
    Local aUserPass := {}
    
    // Validação do header Basic
    If Empty(cAuthBasic)
        cError := "Header de autenticação não informado"
        Return .F.
    EndIf
    
     
    cAuthBasic := StrTran(cAuthBasic, "Basic ", "")
    cUserPass := Decode64(cAuthBasic)
    aUserPass := StrTokArr(cUserPass, ":")
    
    If Len(aUserPass) != 2
        cError := "Formato de autenticação inválido"
        Return .F.
    EndIf
    
    // Aqui irei deixar um usuário e senha padrão, mas podemos 
    // substituir por uma variável de ambiente, banco de dados (cadastro de usuário) ou definição por parametro.
    If aUserPass[1] == "user" .And. aUserPass[2] == "pass"
        lRet := .T.
    Else
        cError := "Usuário ou senha inválidos"
    EndIf
    
Return lRet
