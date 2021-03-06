#if defined(_MSC_VER)
//  Microsoft VC++
#define EXPORT __declspec(dllexport)
#else
//  GCC
#define EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

EXPORT char *generateLuaCode(const char **files, int n);

#ifdef __cplusplus
}
#endif