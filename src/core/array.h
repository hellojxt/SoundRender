#pragma once
#include <cassert>
#include <vector>
#include <iostream>
#include <memory>
#include "macro.h"
#if defined(_WIN32)
typedef unsigned int uint;
#endif
namespace SoundRender
{
	template <typename T>
	class CArr;
	template <typename T>
	class GArr;

	template <typename T>
	class CArr
	{
	public:
		CArr(){};
		CArr(std::vector<T> &x) { m_data = x; };
		CArr(uint num)
		{
			m_data.resize((size_t)num);
		}
		CArr(T *x, uint num)
		{
			m_data.resize((size_t)num);
			for (uint i = 0; i < num; i++)
			{
				m_data[i] = x[i];
			}
		}
		CArr(const GArr<T> &v)
		{
			this->assign(v);
		}
		CArr(const GArr<T> &v, int offset, int count)
		{
			this->assign(v, count, 0, offset);
		}

		~CArr(){};

		void resize(uint n);

		/*!
		 *	\brief	Clear all data to zero.
		 */
		void reset();
		void clear();

		inline const T *begin() const { return m_data.size() == 0 ? nullptr : &m_data[0]; }
		inline T *begin() { return m_data.size() == 0 ? nullptr : &m_data[0]; }
				inline const T *end() const { return m_data.size() == 0 ? nullptr : &m_data[0] + m_data.size(); }
		inline T *end() { return m_data.size() == 0 ? nullptr : &m_data[0] + m_data.size(); }

		inline const T *data() const { return m_data.size() == 0 ? nullptr : &m_data[0]; }
		inline T *data() { return m_data.size() == 0 ? nullptr : &m_data[0]; }

		inline T &operator[](unsigned int id)
		{
			return m_data[id];
		}

		inline const T &operator[](unsigned int id) const
		{
			return m_data[id];
		}

		inline uint size() const { return (uint)m_data.size(); }
		inline bool isEmpty() const { return m_data.empty(); }

		inline void pushBack(T ele) { m_data.push_back(ele); }

		void assign(const T &val);
		void assign(uint num, const T &val);
		void assign(const GArr<T> &src);
		void assign(const CArr<T> &src);
		void assign(const GArr<T> &src, const uint count, const uint dstOffset = 0, const uint srcOffset = 0);
		void assign(const CArr<T> &src, const uint count, const uint dstOffset = 0, const uint srcOffset = 0);
		void assign(const std::vector<T> &src, const uint count, const uint dstOffset = 0, const uint srcOffset = 0);

		friend std::ostream &operator<<(std::ostream &out, const CArr<T> &cArray)
		{
			for (uint i = 0; i < cArray.size(); i++)
			{
				out << i << ": " << cArray[i] << std::endl;
			}

			return out;
		}
		inline GArr<T> gpu()
		{
			return GArr<T>(*this);
		}

		inline std::vector<T> vector()
		{
			return m_data;
		}

	public:
		std::vector<T> m_data;
	};

	/*!
	 *	\class	Array
	 *	\brief	This class is designed to be elegant, so it can be directly passed to GPU as parameters.
	 */
	template <typename T>
	class GArr
	{
	public:
		GArr(){};

		GArr(uint num)
		{
			this->resize(num);
		}

		GArr(T *data_, uint num)
		{
			this->m_data = data_;
			this->m_totalNum = num;
		}

		/*!
		 *	\brief	Do not release memory here, call clear() explicitly.
		 */
		~GArr(){};

		void resize(const uint n);

		/*!
		 *	\brief	Clear all data to zero.
		 */
		void reset();
		void reset_minus_one();
		/*!
		 *	\brief	Free allocated memory.	Should be called before the object is deleted.
		 */
		void clear();

		CGPU_FUNC inline const T *begin() const { return m_data; }
		CGPU_FUNC inline T *begin() { return m_data; }

		CGPU_FUNC inline const T *data() const { return m_data; }
		CGPU_FUNC inline T *data() { return m_data; }

		CGPU_FUNC inline const T *end() const { return m_data + m_totalNum; }
		CGPU_FUNC inline T *end() { return m_data + m_totalNum; }

		GPU_FUNC inline T &operator[](unsigned int id)
		{
			return m_data[id];
		}

		GPU_FUNC inline T &operator[](unsigned int id) const
		{
			return m_data[id];
		}

		CGPU_FUNC inline uint size() const { return m_totalNum; }
		CGPU_FUNC inline bool isCPU() const { return false; }
		CGPU_FUNC inline bool isGPU() const { return true; }
		CGPU_FUNC inline bool isEmpty() const { return m_data == nullptr; }

		void assign(const GArr<T> &src);
		void assign(const CArr<T> &src);
		void assign(const std::vector<T> &src);
		// GArr &operator=(const CArr<T> &v)
		// { this->assign(v); return *this; }
		GArr(const CArr<T> &v)
		{
			this->assign(v);
		}
		inline CArr<T> cget(uint32_t idx, uint32_t count)
		{
			return CArr<T>(*this, idx, count);
		}
		inline T cget(uint32_t idx)
		{
			return CArr<T>(*this, idx, 1)[0];
		}
		inline T last_item()
		{
			return this->cget(m_totalNum - 1);
		}
		inline CArr<T> cpu()
		{
			return CArr<T>(*this);
		}

		void assign(const GArr<T> &src, const uint count, const uint dstOffset = 0, const uint srcOffset = 0);
		void assign(const CArr<T> &src, const uint count, const uint dstOffset = 0, const uint srcOffset = 0);
		void assign(const std::vector<T> &src, const uint count, const uint dstOffset = 0, const uint srcOffset = 0);

		friend std::ostream &operator<<(std::ostream &out, const GArr<T> &dArray)
		{
			CArr<T> hArray;
			hArray.assign(dArray);

			out << hArray;

			return out;
		}

	private:
		T *m_data = 0;
		uint m_totalNum = 0;
	};

	template <typename T, unsigned int N>
	class SArr
	{
	public:
		CGPU_FUNC SArr(){};
		CGPU_FUNC inline T &operator[](unsigned int id)
		{
			return m_data[id];
		}
		CGPU_FUNC inline const T &operator[](unsigned int id) const
		{
			return m_data[id];
		}
		template <typename U, unsigned int M>
		friend std::ostream &operator<<(std::ostream &out, const SArr<U, M> &l)
		{
			out << "(";
			for (int i = 0; i < M - 1; i++)
				out << l[i] << ",";
			out << l[M - 1] << ")";
			return out;
		}

	private:
		T m_data[N];
	};

}

#include "array.inl"