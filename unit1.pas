unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, SysUtils,  fileutil,Forms, Controls,
  Graphics, bgrabitmap, bgrabitmaptypes, Dialogs, StdCtrls,
  shlobj, registry, FPWriteJpeg,
  ComCtrls,LazUTF8;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    CheckBoxresize: TCheckBox;
    Combolockscreen: TComboBox;
    combowallpaper: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    OpenDialog1: TOpenDialog;

    imageselected: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    TrackBar1: TTrackBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    function windowsFolder: string;
    procedure setlockscreen(slockscreenPath: string);
    function getsetpath(): string;
    procedure setdesktop(sWallpaperBMPPath: string);
    procedure DumpExceptionCallStack(E: Exception);


  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  label3.Caption := IntToStr(trackbar1.Position) + '%';
end;

procedure TForm1.Button1Click(Sender: TObject);

begin

  try
    OpenDialog1.Filter := 'Image|*.*';

    if OpenDialog1.Execute then
    begin
      imageselected.Text := OpenDialog1.FileName;
    end
    else
      exit;

    if imageselected.Text = '' then
      exit;


  except
    on E: Exception do
      DumpExceptionCallStack(E);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  newimage, bmp: TBGRABitmap;

  writer: TFPWriterJPEG;

  filepath: string;

begin

  try
    if ((not fileexists(imageselected.Text)) and
      ((combowallpaper.ItemIndex = 1) or (combolockscreen.ItemIndex = 1))) then
    begin
      ShowMessage('File not found!');
      exit;
    end;

    if ((combowallpaper.ItemIndex = 1) or (combolockscreen.ItemIndex = 1)) then

    begin

      try

        bmp := TBGRABitmap.Create;
        bmp.LoadFromfile(imageselected.Text);
        newimage := TBGRABitmap.Create(screen.Width, screen.Height, BGRABlack);


        if (checkboxresize.Checked) then
        begin
           showmessage('w'+inttostr(bmp.width)+'h'+inttostr(bmp.height));
          if bmp.Width > bmp.Height then
          begin
            //width resize right
            bmp.ResampleFilter := rfBestQuality;
            BGRAReplace(bmp,
            // bmp.resample(width,height)
            //bmp.Resample(screen.Width,(screen.Width * bmp.Height) div bmp.Width) as TBGRABitmap);
            bmp.Resample(screen.width,trunc((screen.Height * bmp.Width) / bmp.Width)) as TBGRABitmap);
            showmessage(inttostr((screen.Width * bmp.Height) div bmp.Width));
          end
          else
          begin
            //height resize bottom
            bmp.ResampleFilter := rfBestQuality;
            BGRAReplace(BMP,
            // bmp.resample(width,height)
            bmp.resample(trunc((screen.Height * bmp.Width) / bmp.Height),screen.height) as TBGRABitmap);
          end;

          newimage.PutImage((newimage.width-bmp.width) div 2,(newimage.height-bmp.height) div 2, bmp, dmDrawWithTransparency);
          bgrareplace(bmp, newimage as TBGRABitmap);

        end;



        filepath := getsetpath;

        writer := TFPWriterJPEG.Create;
        writer.CompressionQuality := TrackBar1.Position; //any quality here
        if (combowallpaper.ItemIndex = 1) then
        begin

          bmp.SaveToFile(filepath + 'wallpaper.bmp');
        end;
        if (combolockscreen.ItemIndex = 1) then
        begin
          bmp.SaveToFile(filepath + 'lockscreen.jpg',writer);
        end;

        if ((filesize(filepath + 'lockscreen.jpg') > 256000) and
          (combolockscreen.ItemIndex = 1)) then
        begin
          ShowMessage(filepath + 'lockscreen.jpg too big (' + IntToStr(
            filesize(filepath + 'lockscreen.jpg') div 1024) +
            'kb must be 256kb or less adjust quality! Not setting Lock Screen!');

        end
        else
        if (combolockscreen.ItemIndex = 1) then
          setlockscreen(filepath + 'lockscreen.jpg');



        if (combowallpaper.ItemIndex = 1) then
          setdesktop(filepath + 'wallpaper.bmp');
        ShowMessage('Adjusted Screen');
      finally


        bmp.Free;
        writer.Free;
      end;

    end
    else
    begin
      if ((combowallpaper.ItemIndex = 0) and (combolockscreen.ItemIndex = 0)) then
      begin
        ShowMessage('Nothing to do!');
        exit;
      end;
      if (combowallpaper.ItemIndex = 2) then
        setdesktop('clear');
      if (combolockscreen.ItemIndex = 2) then
        setlockscreen('clear');

      ShowMessage('Adjusted Screen');
    end;

  except
    on E: Exception do
      DumpExceptionCallStack(E);
  end;

end;

function TForm1.windowsFolder: string;
begin
  //SetLength(Result, Windows.MAX_PATH);
  SetLength(
    Result, Windows.getwindowsdirectory(PChar(Result), Windows.MAX_PATH)
    );

end;

procedure TForm1.setlockscreen(slockscreenPath: string);
var
  reg: TRegistry;

begin

  try
    if (slockscreenPath = 'clear') then
    begin

      try
        reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_64KEY);
        reg.Lazywrite := False;
        reg.RootKey := hkey_local_machine;
        if reg.OpenKey(
          'SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background', True) then
        begin
          reg.Writeinteger('OEMBackground', StrToInt('$00000000'));
          SysUtils.ExecuteProcess(UTF8ToSys('rundll32'),
            (UTF8ToSys('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"')), []);
          exit;
        end;
      finally
        reg.Free;
      end;
    end;

    try

      reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_64KEY);
      reg.Lazywrite := False;
      reg.RootKey := hkey_local_machine;
      if reg.OpenKey(
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background', True) then
      begin
        reg.Writeinteger('OEMBackground', StrToInt('$00000001'));

      end;


      if not (directoryexists(windowsfolder + '\SysNative\oobe\info\backgrounds')) then
        createdir(windowsfolder + '\SysNative\oobe\info\backgrounds');
      if (fileexists(windowsfolder +
        '\SysNative\oobe\info\backgrounds\backgroundDefault.jpg')) then
      begin
        deletefile(windowsfolder +
          '\SysNative\oobe\info\backgrounds\backgroundDefault.jpg');
      end;

      copyfile(pchar(slockscreenPath),pchar(
        windowsfolder + '\SysNative\oobe\info\backgrounds\backgroundDefault.jpg'),false);

      SysUtils.ExecuteProcess(UTF8ToSys('rundll32'),
        (UTF8ToSys('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"')), []);

    finally
      reg.Free;
    end;
  except
    on E: Exception do
      DumpExceptionCallStack(E);

  end;

end;

function TForm1.getsetpath(): string;
var
  PersonalPath: array[0..MaxPathLen] of char; //Allocate memory
  filepath: string;

begin

  try
    PersonalPath := '';
    SHGetSpecialFolderPath(0, PersonalPath, CSIDL_PERSONAL, False);

    filepath := PersonalPath + '\changescreen\';
    if not directoryexists(filepath) then
      createdir(filepath);
    Result := filepath;
  except
    on E: Exception do
      DumpExceptionCallStack(E);

  end;
end;

procedure TForm1.setdesktop(sWallpaperBMPPath: string);
var
  reg: TRegistry;
begin
  try

    if (sWallpaperBMPPath = 'clear') then
    begin

      try
        reg := TRegistry.Create;
        reg.Lazywrite := False;
        reg.RootKey := hkey_current_user;

        if reg.OpenKey('Control Panel\Desktop', True) then
        begin

          reg.WriteString('WallpaperStyle', IntToStr(0));
        end;


        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(''),
          SPIF_UPDATEINIFILE);

        SysUtils.ExecuteProcess(UTF8ToSys('rundll32'),
          (UTF8ToSys('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"')), []);
        exit;

      finally
        reg.Free;
      end;

    end;


    try
      reg := TRegistry.Create;
      reg.Lazywrite := False;
      reg.RootKey := hkey_current_user;

      if reg.OpenKey('Control Panel\Desktop', True) then
      begin

        reg.WriteString('WallpaperStyle', IntToStr(0));
      end;


      SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(sWallpaperBMPPath),
        SPIF_UPDATEINIFILE);

      SysUtils.ExecuteProcess(UTF8ToSys('rundll32'),
        (UTF8ToSys('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"')), []);


    finally
      reg.Free;
    end;
  except
    on E: Exception do
      DumpExceptionCallStack(E);

  end;

end;

procedure TForm1.DumpExceptionCallStack(E: Exception);
var

  Report: string;
begin
  report := '';
  if E <> nil then
  begin
    Report := 'Exception class: ' + E.ClassName + ' | Message: ' + E.Message;


    ShowMessage(trim(FormatDateTime('h:nn:ss AM/PM', now) + ' ' +
      FormatDateTime('MM/DD/YYYY', now)) + ' ERROR: ' + report);

  end;
end;

end.
