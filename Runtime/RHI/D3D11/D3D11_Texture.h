/*
Copyright(c) 2016-2018 Panos Karabelas

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
#include <vector>
#include "../IRHI_Texture.h"
//==========================

namespace Directus
{
	class ENGINE_CLASS D3D11_Texture : public IRHI_Texture
	{
	public:
		D3D11_Texture(Context* context);
		~D3D11_Texture();

		bool CreateShaderResource(unsigned int width, unsigned int height, unsigned int channels, const std::vector<std::byte>& data, Texture_Format format) override;					// Simple texture, no mimaps
		bool CreateShaderResource(unsigned int width, unsigned int height, unsigned int channels, const std::vector<std::vector<std::byte>>& mipmaps, Texture_Format format) override;	// With custom-generated mimaps
		bool CreateShaderResource(unsigned int width, int height, unsigned int channels, const std::vector<std::byte>& data, Texture_Format format) override;							// With auto-generated mimaps

		// Shader Resource
		void* GetShaderResource() override								{ return m_shaderResourceView; }
		virtual void SetShaderResource(void* shaderResource) override	{ m_shaderResourceView = (ID3D11ShaderResourceView*)shaderResource;}

		unsigned int GetMemoryUsage() override;

	private:
		ID3D11ShaderResourceView* m_shaderResourceView;
		std::shared_ptr<RHI_Device> m_rhiDevice;
		unsigned int m_memoryUsage;
	};
}
