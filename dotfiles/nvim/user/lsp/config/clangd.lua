-- the offset_encondings of clangd will confilicts whit null-ls
return {
  capabilities = {
     offsetEncoding = "utf-8",
  },
}
