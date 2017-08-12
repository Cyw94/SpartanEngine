/*
Copyright(c) 2016-2017 Panos Karabelas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions :

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#pragma once

//= INCLUDES ===============
#include "../Math/Vector2.h"
#include <fstream>
//==========================

namespace Directus
{
//= RESOLUTION ==========================================
#define SET_RESOLUTION(x,y) Settings::SetResolution(x,y)
#define GET_RESOLUTION Settings::GetResolution()
#define RESOLUTION_WIDTH Settings::GetResolutionWidth()
#define RESOLUTION_HEIGHT Settings::GetResolutionHeight()
//=======================================================

// VIEWPORT ===========================================
#define SET_VIEWPORT(x,y) Settings::SetViewport(x,y)
#define GET_VIEWPORT Settings::GetViewport()
#define VIEWPORT_WIDTH Settings::GetResolutionWidth()
#define VIEWPORT_HEIGHT Settings::GetResolutionHeight()
//=====================================================

#define ASPECT_RATIO Settings::GetScreenAspect()
#define SHADOWMAP_RESOLUTION Settings::GetShadowMapResolution()
#define VSYNC Settings::GetVSync()
#define FULLSCREEN_ENABLED Settings::IsFullScreen()
#define ANISOTROPY_LEVEL Settings::GetAnisotropy()
#define DEBUG_DRAW Settings::GetDebugDraw()

	enum VSync
	{
		Off,
		Every_VBlank,
		Every_Second_VBlank
	};

	class DLL_API Settings
	{
	public:
		static void Initialize();

		//= RESOLUTION ================================================
		static void SetResolution(int width, int height);
		static Math::Vector2 GetResolution();
		static int GetResolutionWidth() { return m_resolutionWidth; }
		static int GetResolutionHeight() { return m_resolutionHeight; }
		//=============================================================

		//= VIEWPORT ==============================================
		static void SetViewport(int width, int height);
		static Math::Vector2 GetViewport();
		static int GetViewportWidth() { return m_viewportWidth; }
		static int GetViewportHeight() { return m_viewportHeight; }
		//=========================================================

		static bool IsFullScreen() { return m_isFullScreen; }
		static bool IsMouseVisible() { return m_isMouseVisible; }
		static VSync GetVSync();
		static float GetScreenAspect() { return m_screenAspect; }
		static int GetShadowMapResolution() { return m_shadowMapResolution; }
		static unsigned int GetAnisotropy() { return m_anisotropy; }
		static void SetDebugDraw(bool enabled) { m_debugDraw = enabled; }
		static bool GetDebugDraw() { return m_debugDraw; }

	private:
		static std::ofstream m_fout;
		static std::ifstream m_fin;
		static std::string m_settingsFileName;

		static bool m_isFullScreen;
		static int m_resolutionWidth;
		static int m_resolutionHeight;
		static int m_viewportWidth;
		static int m_viewportHeight;
		static float m_screenAspect;
		static int m_vsync;
		static bool m_isMouseVisible;		
		static int m_shadowMapResolution;
		static unsigned int m_anisotropy;
		static bool m_debugDraw;	
	};
}