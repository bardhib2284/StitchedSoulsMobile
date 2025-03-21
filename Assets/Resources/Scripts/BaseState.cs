using UnityEngine;

namespace Platformer {
    public abstract class BaseState : IState {
        protected readonly PlayerController player;
        protected readonly Animator animator;
        
        protected static readonly int LocomotionHash = Animator.StringToHash("Locomotion");
        protected static readonly int JumpHash = Animator.StringToHash("Jump");
        protected static readonly int RollHash = Animator.StringToHash("Roll");
        protected static readonly int HammerAttackHash = Animator.StringToHash("Hammer");
        protected static readonly int GunAttackHash = Animator.StringToHash("Attack");
        
        protected const float crossFadeDuration = 0.1f;
        
        protected BaseState(PlayerController player, Animator animator) {
            this.player = player;
            this.animator = animator;
        }
        
        public virtual void OnEnter() {
            // noop
        }

        public virtual void Update() {
            // noop
        }

        public virtual void FixedUpdate() {
            // noop
        }

        public virtual void OnExit() {
            // noop
        }
    }
}