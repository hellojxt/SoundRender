namespace SoundRender
{
	template <typename T>
	void GArr<T>::resize(const uint n)
	{
		//		assert(n >= 1);
		if (m_data != nullptr)
			clear();

		m_totalNum = n;
		if (n == 0)
		{
			m_data = nullptr;
		}
		else
			cuSafeCall(cudaMalloc(&m_data, n * sizeof(T)));
	}

	template <typename T>
	void GArr<T>::clear()
	{
		if (m_data != NULL)
		{
			cuSafeCall(cudaFree((void *)m_data));
		}

		m_data = NULL;
		m_totalNum = 0;
	}

	template <typename T>
	void GArr<T>::reset()
	{
		cuSafeCall(cudaMemset((void *)m_data, 0, m_totalNum * sizeof(T)));
	}

	template <typename T>
	void GArr<T>::reset_minus_one()
	{
		cuSafeCall(cudaMemset((void *)m_data, -1, m_totalNum * sizeof(T)));
	}

	template <typename T>
	void GArr<T>::assign(const GArr<T> &src)
	{
		if (m_totalNum != src.size())
			this->resize(src.size());

		cuSafeCall(cudaMemcpy(m_data, src.begin(), src.size() * sizeof(T), cudaMemcpyDeviceToDevice));
	}

	template <typename T>
	void GArr<T>::assign(const CArr<T> &src)
	{
		if (m_totalNum != src.size())
			this->resize(src.size());

		cuSafeCall(cudaMemcpy(m_data, src.begin(), src.size() * sizeof(T), cudaMemcpyHostToDevice));
	}

	template <typename T>
	void GArr<T>::assign(const std::vector<T> &src)
	{
		if (m_totalNum != src.size())
			this->resize((uint)src.size());

		cuSafeCall(cudaMemcpy(m_data, src.data(), src.size() * sizeof(T), cudaMemcpyHostToDevice));
	}

	template <typename T>
	void GArr<T>::assign(const std::vector<T> &src, const uint count, const uint dstOffset, const uint srcOffset)
	{
		cuSafeCall(cudaMemcpy(m_data + dstOffset, src.begin() + srcOffset, count * sizeof(T), cudaMemcpyHostToDevice));
	}

	template <typename T>
	void GArr<T>::assign(const CArr<T> &src, const uint count, const uint dstOffset, const uint srcOffset)
	{
		cuSafeCall(cudaMemcpy(m_data + dstOffset, src.begin() + srcOffset, count * sizeof(T), cudaMemcpyHostToDevice));
	}

	template <typename T>
	void GArr<T>::assign(const GArr<T> &src, const uint count, const uint dstOffset, const uint srcOffset)
	{
		cuSafeCall(cudaMemcpy(m_data + dstOffset, src.begin() + srcOffset, count * sizeof(T), cudaMemcpyDeviceToDevice));
	}

	template <typename T>
	void CArr<T>::resize(const uint n)
	{
		m_data.resize(n);
	}

	template <typename T>
	void CArr<T>::clear()
	{
		m_data.clear();
	}

	template <typename T>
	void CArr<T>::reset()
	{
		memset((void *)m_data.data(), 0, m_data.size() * sizeof(T));
	}

	template <typename T>
	void CArr<T>::assign(const GArr<T> &src)
	{
		if (m_data.size() != src.size())
			this->resize(src.size());

		cuSafeCall(cudaMemcpy(this->begin(), src.begin(), src.size() * sizeof(T), cudaMemcpyDeviceToHost));
	}

	template <typename T>
	void CArr<T>::assign(const CArr<T> &src)
	{
		if (m_data.size() != src.size())
			this->resize(src.size());

		memcpy(this->begin(), src.begin(), src.size() * sizeof(T));
	}

	template <typename T>
	void CArr<T>::assign(const T &val)
	{
		m_data.assign(m_data.size(), val);
	}

	template <typename T>
	void CArr<T>::assign(uint num, const T &val)
	{
		m_data.assign(num, val);
	}

	template <typename T>
	void CArr<T>::assign(const std::vector<T> &src, const uint count, const uint dstOffset, const uint srcOffset)
	{
		if (m_data.size() != src.size())
			this->resize(src.size());
		memcpy(&m_data[dstOffset], src.begin() + srcOffset, count * sizeof(T));
	}

	template <typename T>
	void CArr<T>::assign(const CArr<T> &src, const uint count, const uint dstOffset, const uint srcOffset)
	{
		if (m_data.size() != src.size())
			this->resize(src.size());
		memcpy(&m_data[dstOffset], src.begin() + srcOffset, count * sizeof(T));
	}

	template <typename T>
	void CArr<T>::assign(const GArr<T> &src, const uint count, const uint dstOffset, const uint srcOffset)
	{
		if (m_data.size() != src.size())
			this->resize(src.size());
		cuSafeCall(cudaMemcpy(&m_data[dstOffset], src.begin() + srcOffset, count * sizeof(T), cudaMemcpyDeviceToHost));
	}

}