# mingw Cookbook

Installs a mingw/msys based compiler tools chain on windows. This is required for compiling C software from source.

## Requirements

### Platforms

- Windows

### Chef

- Chef 15.3+

### Cookbooks

- seven_zip

## Usage

Add this cookbook as a dependency to your cookbook in its `metadata.rb` and include the default recipe in one of your recipes.

```ruby
# metadata.rb
depends 'mingw'
```

```ruby
# your recipe.rb
include_recipe 'mingw::default'
```

Use the `msys2_package` resource in any recipe to fetch msys2 based packages. Use the `mingw_get` resource in any recipe to fetch mingw packages. Use the `mingw_tdm_gcc` resource to fetch a version of the TDM GCC compiler.

By default, you should prefer the msys2 packages as they are newer and better supported. C/C++ compilers on windows use various different exception formats and you need to pick the right one for your task. In the 32-bit world, you have SJLJ (set-jump/long-jump) based exception handling and DWARF-2 (shortened to DW2) based exception handling. SJLJ produces code that can happily throw exceptions across stack frames of code compiled by MSVC. DW2 involves more extensive metadata but produces code that cannot unwind MSVC generated stack-frames - hence you need to ensure that you don't have any code that throws across a "system call". Certain languages and runtimes have specific requirements as to the exception format supported. As an example, if you are building code for Rust, you will probably need a modern gcc from msys2 with DW2 support as that's what the panic/exception formatter in Rust depends on. In a 64-bit world, you may still use SJLJ but compilers all commonly support SEH (structured exception handling).

Of course, to further complicate matters, different versions of different compilers support different exception handling. The default compilers that come with mingw_get are 32-bit only compilers and support DW2\. The TDM compilers come in 3 flavors: a 32-bit only version with SJLJ support, a 32-bit only version with DW2 support and a "multilib" compiler which supports only SJLJ in 32-bit mode but can produce 64-bit SEH code. The standard library support varies drastically between these various compiler flavors (even within the same version). In msys2, you can install a mingw-w64 based compilers for either 32-bit DW2 support or 64-bit SEH support. If all this hurts your brain, I can only apologize.

## Resources

- [minw_get](./documentation/mingw_get.md)
- [mingw_tdm_gcc](./documentation/mingw_tdm_gcc.md)
- [msys2_package](./documentation/msys2_package.md)

## License & Authors

**Author:** Cookbook Engineering Team ([cookbooks@chef.io](mailto:cookbooks@chef.io))

**Copyright:** 2009-2016, Chef Software, Inc.

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
