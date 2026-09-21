#include <windows.h>
#include <shobjidl.h>
#include <wrl.h>
#include <stdio.h>
using Microsoft::WRL::ComPtr;
int wmain(int argc,wchar_t** argv) {
 CoInitializeEx(nullptr,COINIT_APARTMENTTHREADED);
 CLSID cls{}; CLSIDFromString(L"{68BB9D91-43AB-47CE-B772-868D30CD3215}",&cls);
 ComPtr<IExplorerCommand> command;
 HRESULT hr=CoCreateInstance(cls,nullptr,CLSCTX_LOCAL_SERVER,IID_PPV_ARGS(&command));
 if(FAILED(hr)) {wprintf(L"COM activation failed: %08X\n",(unsigned)hr); return 1;}
 PWSTR title=nullptr; hr=command->GetTitle(nullptr,&title); if(FAILED(hr))return 2;
 wprintf(L"COM activated; title: %s\n",title); CoTaskMemFree(title);
 for(int i=1;i<argc;i++) {
  ComPtr<IShellItem> item; hr=SHCreateItemFromParsingName(argv[i],nullptr,IID_PPV_ARGS(&item)); if(FAILED(hr))return 3;
  ComPtr<IShellItemArray> items; hr=SHCreateShellItemArrayFromShellItem(item.Get(),IID_PPV_ARGS(&items)); if(FAILED(hr))return 4;
  EXPCMDSTATE state{}; hr=command->GetState(items.Get(),TRUE,&state);
  wprintf(L"state=%d hr=%08X path=%s\n",state,(unsigned)hr,argv[i]);
  if(FAILED(hr) || state!=static_cast<EXPCMDSTATE>(i==1?ECS_ENABLED:ECS_HIDDEN)) return 5;
 }
 return 0;
}
