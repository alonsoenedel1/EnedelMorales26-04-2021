// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!
table 50100 "Customer Bertonis"
{
    Caption = 'Customer Amount';

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = ToBeClassified;
        }
        field(3; TotalAmount; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = ToBeClassified;
            TableRelation = "Source Code";
        }
    }

    keys
    {
        key(Key1; "Customer No.", "Source Code")
        {
        }
    }

    fieldgroups
    {
    }
}

page 50100 "Customer Bertonis"
{
    PageType = List;
    SourceTable = "Customer Bertonis";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Customer No."; "Customer No.")
                {
                }
                field(Name; Name)
                {
                }
                field("Source Code"; "Source Code")
                {
                }
                field(Total; TotalAmount)
                {
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1000000007; Notes)
            {
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Home)
            {
                Caption = 'CopyData';
                Image = Dimensions;
                action(CopyData)
                {
                    ApplicationArea = Home;
                    Caption = 'Copy Data Bertoni Customer';
                    Image = Copy;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'This action generates total customers grouping it by customer codes registered in accounting for Bertoni.';

                    trigger OnAction()
                    begin
                        cCustBertoni.CopyTotalAmountByCust;
                    end;
                }
            }
        }
    }

    var
        cCustBertoni: Codeunit "Customer Bertonis";
}

codeunit 50100 "Customer Bertonis"
{

    trigger OnRun()
    begin
    end;

    var
        txt001: Label 'Do you want to continue with the process2?';

    procedure CopyTotalAmountByCust()
    var
        rCustomer: Record Customer;
        rGLEntry: Record "G/L Entry";
        rTotalCust: Record "Customer Bertonis";
        lDecTotal: Decimal;
        Dialog: Dialog;
        lIntPaso: Integer;
        rSourceCode: Record "Source Code";
    begin

        if Confirm(txt001, false) then begin
            //Borramos el historial
            rTotalCust.DeleteAll(false);
            Commit;

            //Recorremos los clientes y los buscamos en contabilidad y si hay importe lo ingresamos de nuevo con su importe total

            Dialog.Open('#1', rCustomer."No.");
            rCustomer.Reset;
            if rCustomer.FindFirst then
                repeat
                    Dialog.Update(1, rCustomer."No.");
                    rSourceCode.Reset;
                    if rSourceCode.Findfirst then //Recorro por Source code
                        repeat
                            rGLEntry.Reset;
                            rGLEntry.SetRange("Source No.", rCustomer."No."); //Filtramos por Cliente
                            rGLEntry.SetRange("Source Code", rSourceCode.Code);// Filtramos Source code
                            if rGLEntry.FindFirst then
                                repeat
                                    lDecTotal += rGLEntry."Debit Amount" - rGLEntry."Credit Amount"; //sumamos en variable temporal las líneas
                                    lIntPaso += 1;
                                until rGLEntry.Next <= 0;
                            //Si tenemos importe colocamos el total por cliente e insertamos en nuestra nueva tabla
                            if (lDecTotal <> 0) OR (lIntPaso > 0) then begin
                                rTotalCust.Init;
                                rTotalCust."Customer No." := rCustomer."No.";
                                rTotalCust.Name := rCustomer.Name;
                                rTotalCust.TotalAmount := lDecTotal;
                                rTotalCust."Source Code" := rSourceCode.Code;
                                rTotalCust.Insert(false); //No disparamos triguer
                                Clear(lDecTotal); //Limpiamos variable a 0
                                lIntPaso := 0; //Controlo que pasen por que hay registros que como suman dan 0. Ejemplo CustNo 10000 con SourceCode Sales
                                               //Los que no pasen no los inserto
                            end
                            else begin
                                // si viene en 0 no debería hacernos falta, pero si hace falta los 0 solo se quita esta condición
                            end;
                        until rSourceCode.Next <= 0;
                until rCustomer.Next <= 0;
            Dialog.Close;

        end //End del Confirm
    end;
}
