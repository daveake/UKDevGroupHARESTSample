unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, StrUtils,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Client, REST.Types, System.JSON, REST.Json,
  Vcl.ComCtrls, Vcl.Imaging.jpeg, Vcl.Buttons;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    RESTRequest1: TRESTRequest;
    RESTClient1: TRESTClient;
    RESTResponse1: TRESTResponse;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    TabSheet2: TTabSheet;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Memo2: TMemo;
    TabSheet3: TTabSheet;
    Image1: TImage;
    pnlLanding: TPanel;
    pnlBedroom: TPanel;
    pnlBoxroom: TPanel;
    pnlLounge: TPanel;
    pnlKitchen: TPanel;
    pnlOffice: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    Button9: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private declarations }
    procedure MakeMeHAAPI(EndPoint: String);
    procedure SetMyHeartRate(HeartRate: String);
    procedure ControlSwitch(Entity, State: String);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
    SetMyHeartRate(Edit1.Text);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
    ControlSwitch('switch.usb10', 'off');
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
    MakeMeHAAPI(TButton(Sender).Caption);
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
    ControlSwitch('switch.usb10', 'on');
end;

function FormatJSON(json: String): String;
var
  tmpJson: TJsonValue;
begin
  tmpJson := TJSONObject.ParseJSONValue(json);
  Result := TJson.Format(tmpJson);

  FreeAndNil(tmpJson);
end;

procedure ExtractRoomTemperature(ArrayElement, FoundEntity: TJSonValue; EntityName: String; Panel: TPanel);
var
    Attributes, FoundValue: TJSONValue;
begin
    if FoundEntity.ToString = EntityName then begin
        Attributes := ArrayElement.FindValue('attributes');

        if Attributes <> nil then begin
            FoundValue := Attributes.FindValue('current_temperature');
            if FoundValue <> nil then begin
                Panel.Caption := FoundValue.ToString + '°C';
            end;
        end;
    end;
end;

procedure TForm1.MakeMeHAAPI(EndPoint: String);
var
    JsonArray: TJSONArray;
    JSonValue, ArrayElement, FoundEntity: TJSonValue;
begin
    RESTClient1.BaseURL := 'http://192.168.1.22:8123' + EndPoint;
    RESTRequest1.Method := rmGET;
    RESTRequest1.ClearBody;

    RESTRequest1.Execute;

    JSonValue := RESTResponse1.JSONValue;
    Memo1.Text := JSonValue.ToString;

    Memo2.Text := FormatJSON(JSonValue.ToString);

    if EndPoint = '/api/states' then begin
        JsonValue := TJSonObject.ParseJSONValue(JSonValue.ToString);

        JsonArray := JsonValue as TJSONArray;

        for ArrayElement in JsonArray do begin
            FoundEntity := ArrayElement.FindValue('entity_id');
            if FoundEntity <> nil then begin
                ExtractRoomTemperature(ArrayElement, FoundEntity,'"climate.wiser_office"', pnlOffice);
                ExtractRoomTemperature(ArrayElement, FoundEntity,'"climate.wiser_bedroom"', pnlBedroom);
                ExtractRoomTemperature(ArrayElement, FoundEntity,'"climate.wiser_landing"', pnlLanding);
                ExtractRoomTemperature(ArrayElement, FoundEntity,'"climate.wiser_kitchen"', pnlKitchen);
                ExtractRoomTemperature(ArrayElement, FoundEntity,'"climate.wiser_julie"', pnlBoxroom);
                ExtractRoomTemperature(ArrayElement, FoundEntity,'"climate.wiser_lounge"', pnlLounge);
            end;
        end;
    end;
end;

procedure TForm1.SetMyHeartRate(HeartRate: String);
var
    JSONData, Attributes: TJSONObject;
begin
    RESTClient1.BaseURL := 'http://192.168.1.22:8123/api/states/sensor.me';

    RESTRequest1.Method := rmPOST;
    RESTRequest1.ClearBody;

    JSONData := TJSONObject.Create;
    Attributes := TJSONObject.Create;
    try
        JSONData.AddPair('state', HeartRate);

        Attributes.AddPair('unit_of_measurement', 'bpm');
        Attributes.AddPair('friendly_name', 'Heart Rate');

        JSONData.AddPair('attributes', Attributes);

        // Set the request body to the JSON data
        RESTRequest1.AddBody(JSONData.ToString, ContentTypeFromString('application/json'));

        // Send the request
        RESTRequest1.Execute;
    finally
        JSONData.Free;
        // Attributes.Free;
    end;
end;

procedure TForm1.ControlSwitch(Entity, State: String);
var
    JSONData: TJSONObject;
begin
    RESTClient1.BaseURL := 'http://192.168.1.22:8123/api/services/switch/turn_' + State;
    RESTRequest1.Method := rmPOST;
    RESTRequest1.ClearBody;

    JSONData := TJSONObject.Create;
    try
      JSONData.AddPair('entity_id', Entity);

      // Set the request body to the JSON data
      RESTRequest1.ClearBody;
      RESTRequest1.AddBody(JSONData.ToString, ContentTypeFromString('application/json'));

      // Send the request
      RESTRequest1.Execute;
    finally
        JSONData.Free;
    end;
end;

end.

