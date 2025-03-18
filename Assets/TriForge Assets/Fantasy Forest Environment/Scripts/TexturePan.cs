using UnityEngine;
using System.Collections;

namespace TriForge
{
	public class TexturePan : MonoBehaviour
	{
		public float scrollSpeed = 1.0f;
		Renderer rend;

		void Start()
		{
			rend = GetComponent<Renderer>();
		}

		void Update()
		{
			float offset = Time.time * scrollSpeed;
			rend.material.mainTextureOffset = new Vector2(0, offset);
		}
	}
}

