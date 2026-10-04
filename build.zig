const std = @import("std");
const system = @import("system");

const Dependencies = struct {
  bc: *std.Build.Dependency,
  common: *std.Build.Dependency,
  squall: *std.Build.Dependency,
  typhoon: *std.Build.Dependency,

  lua: *std.Build.Dependency,
  freetype: *std.Build.Dependency,
  stormlib: *std.Build.Dependency,

  sdl: *std.Build.Dependency,
  glew: *std.Build.Dependency,
};

var dependencies: Dependencies = undefined;

fn get_dependencies(b: *std.Build) void {
  const d = &dependencies;

  d.bc = b.dependency("bc", .{});
  d.common = b.dependency("common", .{});
  d.squall = b.dependency("squall", .{});
  d.typhoon = b.dependency("typhoon", .{});

  d.lua = b.dependency("lua", .{});
  d.freetype = b.dependency("freetype", .{});
  d.stormlib = b.dependency("stormlib", .{});

  d.sdl = b.dependency("sdl", .{});
  d.glew = b.dependency("glew", .{});
}

fn link_core_dependencies(c: *std.Build.Step.Compile) void {
  const d = &dependencies;
  // link bc
  c.linkLibrary(d.bc.artifact("bc"));
  // link common
  c.linkLibrary(d.common.artifact("common"));
  // link squall
  c.linkLibrary(d.squall.artifact("storm"));
  // link typhoon
  c.linkLibrary(d.typhoon.artifact("tempest"));

  // link stormlib
  c.linkLibrary(d.stormlib.artifact("stormlib"));
  // link lua
  c.linkLibrary(d.lua.artifact("lua"));
  // link freetype
  c.linkLibrary(d.freetype.artifact("freetype"));
}

fn link_glsdl_dependencies(target: std.Build.ResolvedTarget, c: *std.Build.Step.Compile) void {
  const t = &target.result;
  const d = &dependencies;
  // link SDL
  c.linkLibrary(d.sdl.artifact("SDL2"));
  // link GLEW
  c.linkLibrary(d.glew.artifact("glew"));
  // Make headers work in static mode
  c.defineCMacro("GLEW_STATIC", "1");
  // on windows, link opengl32.lib
  if (t.os.tag == .windows) {
    c.linkSystemLibrary("opengl32");
  }
}

pub fn build(b: *std.Build) void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  // Build options

  // UBsan
  const ub_san_help_text = "Enable/Disable the Undefined Behavior Sanitizer";
  const ub_san_option = b.option(bool, "WHOA_UB_SAN", ub_san_help_text);
  var ub_san: bool = undefined;

  // UB san is enabled or disabled by default, depending on what mode we're in
  switch (optimize) {
    .Debug => {
      ub_san = true;
    },
    .ReleaseSafe => {
      ub_san = true;
    },
    .ReleaseSmall => {
      ub_san = false;
    },
    .ReleaseFast => {
      ub_san = false;
    }
  }
  if (ub_san_option != null) {
    ub_san = ub_san_option.?;
  }
  const whoa_base_compiler_flags = [_][]const u8 {
    "-std=c++11",
    // Allow templates to abuse offsetof
    "-Wno-invalid-offsetof",
  };
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  var whoa_compiler_flags_list = std.ArrayList([]const u8).init(gpa.allocator());
  defer _ = whoa_compiler_flags_list.deinit();
  whoa_compiler_flags_list.appendSlice(&whoa_base_compiler_flags) catch {};

  const t = &target.result;

  if (ub_san) {
    // Disable UBsan alignment checks only
    whoa_compiler_flags_list.append("-fno-sanitize=alignment") catch {};
    whoa_compiler_flags_list.append("-fno-sanitize=float-cast-overflow") catch {};
    whoa_compiler_flags_list.append("-fno-sanitize=signed-integer-overflow") catch {};
  } else {
    // Disable UBsan
    whoa_compiler_flags_list.append("-fno-sanitize=all") catch {};
  }

  var build_gll = false;
  var build_d3d = false;
  var build_glsdl = false;

  // GLSDL
  const build_glsdl_option = b.option(bool, "WHOA_BUILD_GLSDL", "Enable");
  switch (t.os.tag) {
    .windows => {
      // SDL is off by default
      build_glsdl = build_glsdl_option orelse false;
      build_d3d = true;
    },

    .macos => {
      // macos can't really compile SDL easily
      build_glsdl = false;
      build_gll = true;
    },

    else => {
      // GLSDL on by default
      build_glsdl = build_glsdl_option orelse true;
    }
  }

  // FMOD
  // const build_fmod_option = b.option(bool, "WHOA_BUILD_FMOD", "Enable");

  const whoa_compiler_flags = whoa_compiler_flags_list.items;

  // dependencies
  get_dependencies(b);

  const whoa_core = b.addStaticLibrary(.{
    .name = "whoa_core",
    .target = target,
    .optimize = optimize
  });

  // Add system detection defines
  system.add_defines(whoa_core);
  // Link C++ standard library
  whoa_core.linkLibCpp();
  // Include "src/"
  whoa_core.addIncludePath(b.path("src"));

  link_core_dependencies(whoa_core);

  // OS defines

  if (t.os.tag == .windows) {
    whoa_core.defineCMacro("NOMINMAX", "1");
    whoa_core.defineCMacro("WIN32_LEAN_AND_MEAN", "1");

    whoa_core.defineCMacro("_XM_NO_INTRINSICS_", "1");
  }

  // ****************
  // * async module *
  // ****************
  const whoa_async_sources = [_][]const u8 {
    "src/async/AsyncFile.cpp",
    "src/async/AsyncFileRead.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_async_sources,
    .flags = whoa_compiler_flags
  });

  // *****************
  // * client module *
  // *****************
  const whoa_client_sources = [_][]const u8 {
    "src/client/Client.cpp",
    "src/client/ClientRealmResponseAdapter.cpp",
    "src/client/ClientServices.cpp",
    "src/client/CmdLine.cpp"
  };

  const whoa_client_windows_sources = [_][]const u8 {
    "src/client/gui/win/OsGui.cpp",
  };

  const whoa_client_macos_sources = [_][]const u8 {
    "src/client/gui/mac/OsGui.cpp",
  };

  const whoa_client_linux_sources = [_][]const u8 {
    "src/client/gui/linux/OsGui.cpp",
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_client_sources,
    .flags = whoa_compiler_flags
  });

  switch (t.os.tag) {
    .windows => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_client_windows_sources,
        .flags = whoa_compiler_flags
      });
    },
    
    .macos => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_client_macos_sources,
        .flags = whoa_compiler_flags
      });
    },

    else => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_client_linux_sources,
        .flags = whoa_compiler_flags
      });
    }
  }

  // ******************
  // * console module *
  // ******************
  const whoa_console_sources = [_][]const u8 {
    "src/console/Client.cpp",
    "src/console/Command.cpp",
    "src/console/Console.cpp",
    "src/console/CVar.cpp",
    "src/console/Device.cpp",
    "src/console/Handlers.cpp",
    "src/console/Line.cpp",
    "src/console/Screen.cpp",

    "src/console/command/console/AppendLogToFile.cpp",
    "src/console/command/console/BackGroundColor.cpp",
    "src/console/command/console/BufferSize.cpp",
    "src/console/command/console/CharSpacing.cpp",
    "src/console/command/console/ClearConsole.cpp",
    "src/console/command/console/CloseConsole.cpp",
    "src/console/command/console/CurrentSettings.cpp",
    "src/console/command/console/DefaultSettings.cpp",
    "src/console/command/console/Font.cpp",
    "src/console/command/console/FontColor.cpp",
    "src/console/command/console/FontSize.cpp",
    "src/console/command/console/Help.cpp",
    "src/console/command/console/HighLightColor.cpp",
    "src/console/command/console/Proportional.cpp",
    "src/console/command/console/RepeatHandler.cpp",
    "src/console/command/console/Ver.cpp",

    "src/console/command/default/Quit.cpp",
    "src/console/command/default/SetMap.cpp",
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_console_sources,
    .flags = whoa_compiler_flags
  });

  // *************
  // * db module *
  // *************
  const whoa_db_sources = [_][]const u8 {
    "src/db/Db.cpp",

    // TODO: replace with full list of generated records
    "src/db/rec/AchievementRec.cpp",
    "src/db/rec/Cfg_CategoriesRec.cpp",
    "src/db/rec/Cfg_ConfigsRec.cpp",
    "src/db/rec/ChrRacesRec.cpp",
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_db_sources,
    .flags = whoa_compiler_flags
  });

  // ****************
  // * event module *
  // ****************
  const whoa_event_sources = [_][]const u8 {
    "src/event/CEvent.cpp",
    "src/event/Context.cpp",
    "src/event/Event.cpp",
    "src/event/EvtContext.cpp",
    "src/event/EvtThread.cpp",
    "src/event/Input.cpp",
    "src/event/Queue.cpp",
    "src/event/Scheduler.cpp",
    "src/event/Synthesize.cpp",
    "src/event/Timer.cpp"
  };

  const whoa_event_windows_sources = [_][]const u8 {
    "src/event/win/Input.cpp",
  };

  const whoa_event_macos_sources = [_][]const u8 {
    "src/event/mac/Input.cpp",
    "src/event/mac/Event.mm",
  };

  const whoa_event_linux_sources = [_][]const u8 {
    "src/event/linux/Input.cpp",
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_event_sources,
    .flags = whoa_compiler_flags
  });

  switch (t.os.tag) {
    .windows => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_event_windows_sources,
        .flags = whoa_compiler_flags
      });
    },
    
    .macos => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_event_macos_sources,
        .flags = whoa_compiler_flags
      });
    },

    else => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_event_linux_sources,
        .flags = whoa_compiler_flags
      });
    }
  }

  // ***************
  // * glue module *
  // ***************
  const whoa_glue_sources = [_][]const u8 {
    "src/glue/CCharacterSelection.cpp",
    "src/glue/CGlueMgr.cpp",
    "src/glue/CRealmList.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_glue_sources,
    .flags = whoa_compiler_flags
  });

  // *************
  // * gx module *
  // *************
  const whoa_gx_sources = [_][]const u8 {
    "src/gx/Blit.cpp",
    "src/gx/Buffer.cpp",
    "src/gx/Camera.cpp",
    "src/gx/CCamera.cpp",
    "src/gx/CGVideoOptions.cpp",
    "src/gx/CGxDevice.cpp",
    "src/gx/CGxMatrixStack.cpp",
    "src/gx/CGxStateBom.cpp",
    "src/gx/Coordinate.cpp",
    "src/gx/Device.cpp",
    "src/gx/Draw.cpp",
    "src/gx/Font.cpp",
    "src/gx/FontInternal.cpp",
    "src/gx/Gx.cpp",
    "src/gx/RenderState.cpp",
    "src/gx/Screen.cpp",
    "src/gx/Shader.cpp",
    "src/gx/Texture.cpp",
    "src/gx/Transform.cpp",
    "src/gx/Window.cpp",

    "src/gx/buffer/CGxPool.cpp",

    "src/gx/font/CGxFont.cpp",
    "src/gx/font/CGxString.cpp",
    "src/gx/font/CGxStringBatch.cpp",
    "src/gx/font/FaceData.cpp",
    "src/gx/font/FontFace.cpp",
    "src/gx/font/FreeType.cpp",
    "src/gx/font/FreeTypeInternal.cpp",
    "src/gx/font/Wrap.cpp",

    "src/gx/shader/CGxShader.cpp",
    "src/gx/shader/CShaderEffect.cpp",
    "src/gx/shader/CShaderEffectManager.cpp",

    "src/gx/texture/CBLPFile.cpp", 
    "src/gx/texture/CGxTex.cpp", 
    "src/gx/texture/CTexture.cpp"
  };

  const whoa_gx_d3d_sources = [_][]const u8 {
    "src/gx/d3d/CGxDeviceD3d.cpp"
  };

  const whoa_gx_gll_sources = [_][]const u8 {
    "src/gx/gll/CGxDeviceGLL.cpp",
    "src/gx/gll/GL.cpp",
    "src/gx/gll/GLAbstractWindow.cpp",
    "src/gx/gll/GLBuffer.cpp",
    "src/gx/gll/GLCommand.cpp",
    "src/gx/gll/GLContext.mm",
    "src/gx/gll/GLDevice.cpp",
    "src/gx/gll/GLFramebuffer.cpp",
    "src/gx/gll/GLGLSLProgram.cpp",
    "src/gx/gll/GLLayerView.mm",
    "src/gx/gll/GLMipmap.cpp",
    "src/gx/gll/GLObject.cpp",
    "src/gx/gll/GLPixelShader.cpp",
    "src/gx/gll/GLShader.cpp",
    "src/gx/gll/GLTexture.cpp",
    "src/gx/gll/GLTypes.cpp",
    "src/gx/gll/GLUtil.cpp",
    "src/gx/gll/GLVertexArray.cpp",
    "src/gx/gll/GLVertexShader.cpp",
    "src/gx/gll/GLWindow.mm",
    "src/gx/gll/GLWorker.cpp"
  };

  const whoa_gx_glsdl_sources = [_][]const u8 {
    "src/gx/glsdl/CGxDeviceGLSDL.cpp",
    "src/gx/glsdl/GL.cpp",
    "src/gx/glsdl/GLBuffer.cpp",
    "src/gx/glsdl/GLFramebuffer.cpp",
    "src/gx/glsdl/GLGLSLProgram.cpp",
    "src/gx/glsdl/GLMipmap.cpp",
    "src/gx/glsdl/GLObject.cpp",
    "src/gx/glsdl/GLPixelShader.cpp",
    "src/gx/glsdl/GLSDLContext.cpp",
    "src/gx/glsdl/GLSDLDevice.cpp",
    "src/gx/glsdl/GLSDLWindow.cpp",
    "src/gx/glsdl/GLShader.cpp",
    "src/gx/glsdl/GLTexture.cpp",
    "src/gx/glsdl/GLTypes.cpp",
    "src/gx/glsdl/GLUtil.cpp",
    "src/gx/glsdl/GLVertexArray.cpp",
    "src/gx/glsdl/GLVertexShader.cpp"
  };


  whoa_core.addCSourceFiles(.{
    .files = &whoa_gx_sources,
    .flags = whoa_compiler_flags
  });


  if (build_d3d) {
    whoa_core.addCSourceFiles(.{
      .files = &whoa_gx_d3d_sources,
      .flags = whoa_compiler_flags
    });
    whoa_core.linkSystemLibrary("d3d9");
  }

  if (build_gll) {
    whoa_core.addCSourceFiles(.{
      .files = &whoa_gx_gll_sources,
      .flags = whoa_compiler_flags
    });
    whoa_core.linkFramework("AppKit");
    whoa_core.linkFramework("OpenGL");
  }

  if (build_glsdl) {
    whoa_core.addCSourceFiles(.{
      .files = &whoa_gx_glsdl_sources,
      .flags = whoa_compiler_flags
    });

    whoa_core.defineCMacro("WHOA_BUILD_GLSDL", "1");

    link_glsdl_dependencies(target, whoa_core);
  }

  // ***************
  // * math module *
  const whoa_math_sources = [_][]const u8 {
    "src/math/Types.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_math_sources,
    .flags = whoa_compiler_flags
  });

  // ****************
  // * model module *
  // ****************
  const whoa_model_sources = [_][]const u8 {
    "src/model/CM2Cache.cpp",
    "src/model/CM2Light.cpp",
    "src/model/CM2Lighting.cpp",
    "src/model/CM2Model.cpp",
    "src/model/CM2Scene.cpp",
    "src/model/CM2SceneRender.cpp",
    "src/model/CM2Shared.cpp",
    "src/model/M2Init.cpp",
    "src/model/M2Internal.cpp",
    "src/model/M2Sort.cpp",
    "src/model/Model2.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_model_sources,
    .flags = whoa_compiler_flags
  });
  
  // **************
  // * net module *
  // **************
  const whoa_net_sources = [_][]const u8 {
    "src/net/Poll.cpp",

    "src/net/connection/ClientConnection.cpp",
    "src/net/connection/NetClient.cpp",
    "src/net/connection/RealmConnection.cpp",
    "src/net/connection/WowConnection.cpp",
    "src/net/connection/WowConnectionNet.cpp",

    "src/net/grunt/ClientLink.cpp",
    "src/net/grunt/Grunt.cpp",
    "src/net/grunt/Timer.cpp",

    "src/net/login/GruntLogin.cpp",
    "src/net/login/Login.cpp",
    "src/net/login/LoginResponse.cpp",

    "src/net/srp/SRP6_Client.cpp",
    "src/net/srp/SRP6_Random.cpp",
  };

  const whoa_net_winsock_sources = [_][]const u8 {
    "src/net/connection/winsock/WowConnectionNet.cpp"
  };

  const whoa_net_bsd_sources = [_][]const u8 {
    "src/net/connection/bsd/WowConnectionNet.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_net_sources,
    .flags = whoa_compiler_flags
  });

  switch (t.os.tag) {
    .windows => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_net_winsock_sources,
        .flags = whoa_compiler_flags
      });
      whoa_core.linkSystemLibrary("wsock32");
      whoa_core.linkSystemLibrary("ws2_32");
    },

    else => {
      whoa_core.addCSourceFiles(.{
        .files = &whoa_net_bsd_sources,
        .flags = whoa_compiler_flags
      });
    }
  }

  // // *************
  // // * os module *
  // // *************
  // const whoa_os = b.addStaticLibrary(.{
  //   .name = "os",
  //   .target = target,
  //   .optimize = optimize
  // });
  // // Add system detection defines
  // system.add_defines(whoa_os);
  // // Link C++ standard library
  // whoa_os.linkLibCpp();
  // // Include "src/"
  // whoa_os.addIncludePath(b.path("src"));

  // ****************
  // * sound module *
  // ****************
  const whoa_sound_sources = [_][]const u8 {
    "src/sound/SI2.cpp",
    "src/sound/SI2Cvars.cpp",
    "src/sound/SI2Log.cpp",
    "src/sound/SI2Script.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_sound_sources,
    .flags = whoa_compiler_flags
  });

  // *************
  // * ui module *
  // *************
  const whoa_ui_sources = [_][]const u8 {
    "src/ui/CBackdropGenerator.cpp",
    "src/ui/CFramePoint.cpp",
    "src/ui/CFrameStrata.cpp",
    "src/ui/CLayoutFrame.cpp",
    "src/ui/CRenderBatch.cpp",
    "src/ui/CScriptObject.cpp",
    "src/ui/CScriptObjectScript.cpp",
    "src/ui/CScriptRegion.cpp",
    "src/ui/CScriptRegionScript.cpp",
    "src/ui/CSimpleButton.cpp",
    "src/ui/CSimpleButtonScript.cpp",
    "src/ui/CSimpleCheckbox.cpp",
    "src/ui/CSimpleCheckboxScript.cpp",
    "src/ui/CSimpleEditBox.cpp",
    "src/ui/CSimpleEditBoxScript.cpp",
    "src/ui/CSimpleFont.cpp",
    "src/ui/CSimpleFontable.cpp",
    "src/ui/CSimpleFontScript.cpp",
    "src/ui/CSimpleFontString.cpp",
    "src/ui/CSimpleFontStringAttributes.cpp",
    "src/ui/CSimpleFontStringScript.cpp",
    "src/ui/CSimpleFrame.cpp",
    "src/ui/CSimpleFrameScript.cpp",
    "src/ui/CSimpleHTML.cpp",
    "src/ui/CSimpleHTMLScript.cpp",
    "src/ui/CSimpleHyperlinkedFrame.cpp",
    "src/ui/CSimpleModel.cpp",
    "src/ui/CSimpleModelFFX.cpp",
    "src/ui/CSimpleModelFFXScript.cpp",
    "src/ui/CSimpleModelScript.cpp",
    "src/ui/CSimpleRegion.cpp",
    "src/ui/CSimpleRender.cpp",
    "src/ui/CSimpleScrollFrame.cpp",
    "src/ui/CSimpleScrollFrameScript.cpp",
    "src/ui/CSimpleSlider.cpp",
    "src/ui/CSimpleSliderScript.cpp",
    "src/ui/CSimpleTexture.cpp",
    "src/ui/CSimpleTextureScript.cpp",
    "src/ui/CSimpleTop.cpp",
    "src/ui/FrameScript_Object.cpp",
    "src/ui/FrameScript.cpp",
    "src/ui/FrameXML.cpp",
    "src/ui/Interface.cpp",
    "src/ui/LoadXML.cpp",
    "src/ui/LuaExtraFuncs.cpp",
    "src/ui/LuaMemory.cpp",
    "src/ui/ScriptFunctions.cpp",
    "src/ui/ScriptFunctionsCharCreate.cpp",
    "src/ui/ScriptFunctionsCharSelect.cpp",
    "src/ui/ScriptFunctionsGlueScriptEvents.cpp",
    "src/ui/ScriptFunctionsRealmList.cpp",
    "src/ui/ScriptFunctionsShared.cpp",
    "src/ui/ScriptFunctionsSimpleFrame.cpp",
    "src/ui/ScriptFunctionsSystem.cpp",
    "src/ui/Util.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_ui_sources,
    .flags = whoa_compiler_flags
  });

  // ***************
  // * util module *
  // ***************
  const whoa_util_sources = [_][]const u8 {
    "src/util/CStatus.cpp",
    "src/util/Filesystem.cpp",
    "src/util/HMAC.cpp",
    "src/util/SFile.cpp",
    "src/util/StringTo.cpp",
    "src/util/SysMessage.cpp"
  };

  const whoa_util_macos_sources = [_][]const u8 {
    "src/util/Autorelease.mm"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_util_sources,
    .flags = whoa_compiler_flags
  });

  if (t.os.tag == .macos) {
    whoa_core.addCSourceFiles(.{
      .files = &whoa_util_macos_sources,
      .flags = whoa_compiler_flags
    });
  }

  // ****************
  // * world module *
  // ****************
  const whoa_world_sources = [_][]const u8 {
    "src/world/CWorld.cpp"
  };

  whoa_core.addCSourceFiles(.{
    .files = &whoa_world_sources,
    .flags = whoa_compiler_flags
  });

  // **************
  // * app module *
  // **************
  const whoa_app = b.addExecutable(.{
    .name = "Northrend",
    .target = target,
    .optimize = optimize
  });
  // Add system detection defines
  system.add_defines(whoa_app);
  // Link C++ standard library
  whoa_app.linkLibCpp();
  // Include "src/"
  whoa_app.addIncludePath(b.path("src"));

  const whoa_app_windows_sources = [_][]const u8 {
    "src/app/win/Whoa.cpp",
    "src/app/win/Whoa.rc"
  };

  const whoa_app_macos_sources = [_][]const u8 {
    "src/app/macos/MacClient.mm",
    "src/app/macos/MainApp.mm",
    "src/app/macos/Whoa.mm",
    "src/app/macos/View.mm",
    "src/app/macos/WindowsCallbacks.mm",
    "src/app/macos/WoWApplication.mm",
  };

  const whoa_app_linux_sources = [_][]const u8 {
    "src/app/linux/Whoa.cpp",
  };

  switch (t.os.tag) {
    .windows => {
      whoa_app.addCSourceFiles(.{
        .files = &whoa_app_windows_sources,
        .flags = whoa_compiler_flags
      });
    },
    
    .macos => {
      whoa_app.addCSourceFiles(.{
        .files = &whoa_app_macos_sources,
        .flags = whoa_compiler_flags
      });
    },

    else => {
      whoa_app.addCSourceFiles(.{
        .files = &whoa_app_linux_sources,
        .flags = whoa_compiler_flags
      });
    }
  }

  link_core_dependencies(whoa_app);

  whoa_app.linkLibrary(whoa_core);

  b.installArtifact(whoa_app);
}