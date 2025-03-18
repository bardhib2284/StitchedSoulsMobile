using UnityEngine;
using System.Collections;
using Assets.Resources.Scripts;

public class ShotBehavior : MonoBehaviour {

    public Transform enemy;
	// Use this for initialization
	void Start () {
    }

    // Update is called once per frame
    void Update () {
        if (enemy != null)
        {
            transform.position = Vector3.MoveTowards(transform.position, new Vector3(enemy.position.x,enemy.position.y + 0.1f, enemy.position.z), 0.1f);
            var dis = Vector3.Distance(transform.position, enemy.position);
            if (dis <= 0.3)
            {
                Destroy(this.gameObject);
            }
        }
        else
        {
            transform.position += transform.forward * Time.deltaTime * 10f;
            Destroy(this.gameObject, 0.5f);
        }

    }
}
