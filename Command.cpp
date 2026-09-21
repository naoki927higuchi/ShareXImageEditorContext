#include <windows.h>
#include <shobjidl.h>
#include <shlwapi.h>
#include <wrl.h>
#include <wrl/module.h>
#include <string>
using namespace Microsoft::WRL;
static std::wstring ShareXPath() {
 wchar_t path[32768]{}; DWORD size=sizeof(path);
 if(RegGetValueW(HKEY_CURRENT_USER,L"Software\\ShareXImageEditorContext",L"ShareXPath",RRF_RT_REG_SZ,nullptr,path,&size)==ERROR_SUCCESS) return path;
 return L"C:\\Program Files\\ShareX\\ShareX.exe";
}
class __declspec(uuid("68BB9D91-43AB-47CE-B772-868D30CD3215")) Command final : public RuntimeClass<RuntimeClassFlags<ClassicCom>, IExplorerCommand> {
public:
 HRESULT STDMETHODCALLTYPE GetTitle(IShellItemArray*,PWSTR* p) override { return SHStrDupW(L"ShareXイメージエディタで開く",p); }
 HRESULT STDMETHODCALLTYPE GetIcon(IShellItemArray*,PWSTR* p) override { return SHStrDupW((ShareXPath()+L",0").c_str(),p); }
 HRESULT STDMETHODCALLTYPE GetToolTip(IShellItemArray*,PWSTR* p) override { *p=nullptr; return E_NOTIMPL; }
 HRESULT STDMETHODCALLTYPE GetCanonicalName(GUID* p) override { *p=__uuidof(Command); return S_OK; }
 HRESULT STDMETHODCALLTYPE GetState(IShellItemArray* items,BOOL,EXPCMDSTATE* state) override {
  *state=ECS_HIDDEN; DWORD count=0;
  if(!items || FAILED(items->GetCount(&count)) || !count) return S_OK;
  for(DWORD i=0;i<count;i++) {
   ComPtr<IShellItem> item; if(FAILED(items->GetItemAt(i,&item))) return S_OK;
   PWSTR path=nullptr; if(FAILED(item->GetDisplayName(SIGDN_FILESYSPATH,&path))) return S_OK;
   auto ext=PathFindExtensionW(path); bool image=false;
   for(auto allowed:{L".png",L".jpg",L".jpeg",L".bmp",L".gif",L".tif",L".tiff",L".webp",L".ico"}) if(!_wcsicmp(ext,allowed)) image=true;
   CoTaskMemFree(path); if(!image) return S_OK;
  }
  *state=ECS_ENABLED; return S_OK;
 }
 HRESULT STDMETHODCALLTYPE Invoke(IShellItemArray* items,IBindCtx*) override {
  if(!items) return E_INVALIDARG; DWORD count=0; HRESULT hr=items->GetCount(&count); if(FAILED(hr)) return hr;
  auto exe=ShareXPath();
  for(DWORD i=0;i<count;i++) {
   ComPtr<IShellItem> item; hr=items->GetItemAt(i,&item); if(FAILED(hr)) return hr;
   PWSTR path=nullptr; hr=item->GetDisplayName(SIGDN_FILESYSPATH,&path); if(FAILED(hr)) return hr;
   std::wstring cmd=L"\""+exe+L"\" -ImageEditor \""+path+L"\""; CoTaskMemFree(path);
   STARTUPINFOW si{sizeof(si)}; PROCESS_INFORMATION pi{};
   if(!CreateProcessW(exe.c_str(),cmd.data(),nullptr,nullptr,FALSE,0,nullptr,nullptr,&si,&pi)) return HRESULT_FROM_WIN32(GetLastError());
   CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
  } return S_OK;
 }
 HRESULT STDMETHODCALLTYPE GetFlags(EXPCMDFLAGS* p) override { *p=ECF_DEFAULT; return S_OK; }
 HRESULT STDMETHODCALLTYPE EnumSubCommands(IEnumExplorerCommand** p) override { *p=nullptr; return E_NOTIMPL; }
};
CoCreatableClass(Command);
extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID cls,REFIID iid,void** result) {return Module<InProc>::GetModule().GetClassObject(cls,iid,result);}
extern "C" HRESULT __stdcall DllCanUnloadNow() {return Module<InProc>::GetModule().GetObjectCount()==0?S_OK:S_FALSE;}
