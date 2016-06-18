/*
Copyright(c) 2016 Panos Karabelas

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

#define DIRECTINPUT_VERSION 0x0800

//= LINKING ===========================
#pragma comment(lib, "dinput8.lib")
#pragma comment(lib, "dxguid.lib")
//=====================================

//= INCLUDES ================
#include "../Math/Vector3.h"
#include <dinput.h>

//===========================

class DX8Input
{
public:
	DX8Input();
	~DX8Input();

	void Initialize(HINSTANCE instance, HWND handle);
	void Update();
	void Release();

	bool IsKeyboardKeyDown(byte key);
	bool IsMouseKeyDown(int key);

	Directus::Math::Vector3 GetMouseDelta();

private:
	bool ReadKeyboard();
	bool ReadMouse();

	IDirectInput8* m_directInput;
	IDirectInputDevice8* m_keyboard;
	IDirectInputDevice8* m_mouse;

	unsigned char m_keyboardState[256];
	DIMOUSESTATE m_mouseState;
};
