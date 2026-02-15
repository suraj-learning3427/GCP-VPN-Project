// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Animate elements on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all cards and sections
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll(
        '.overview-card, .component-card, .benefit-card, .security-layer, .timeline-item'
    );
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        observer.observe(el);
    });

    // Animate cost chart bars
    const chartBars = document.querySelectorAll('.bar-fill');
    const chartObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.width = entry.target.parentElement.style.getPropertyValue('--percentage');
            }
        });
    }, observerOptions);

    chartBars.forEach(bar => {
        chartObserver.observe(bar);
    });

    // Add active state to navigation on scroll
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-links a');

    window.addEventListener('scroll', () => {
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (window.pageYOffset >= sectionTop - 200) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.style.color = '';
            if (link.getAttribute('href') === `#${current}`) {
                link.style.color = 'var(--secondary-color)';
            }
        });
    });

    // Add hover effect to component cards
    const componentCards = document.querySelectorAll('.component-card');
    componentCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-10px) scale(1.02)';
        });
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });

    // Animate stats on hero section
    const statValues = document.querySelectorAll('.stat-value');
    statValues.forEach(stat => {
        const text = stat.textContent;
        if (text.includes('$')) {
            animateNumber(stat, 0, 768, 2000, '$');
        } else if (text.includes('%')) {
            animateNumber(stat, 0, 100, 1500, '', '%');
        } else if (text.includes('min')) {
            animateNumber(stat, 0, 20, 1500, '', 'min');
        } else if (!isNaN(parseInt(text))) {
            animateNumber(stat, 0, parseInt(text), 1500);
        }
    });

    // Add click effect to timeline items
    const timelineItems = document.querySelectorAll('.timeline-item');
    timelineItems.forEach((item, index) => {
        item.style.animationDelay = `${index * 0.2}s`;
    });

    // Add tooltip functionality
    addTooltips();

    // Initialize cost comparison animation
    animateCostComparison();

    // Add keyboard navigation
    document.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowDown') {
            scrollToNextSection();
        } else if (e.key === 'ArrowUp') {
            scrollToPreviousSection();
        }
    });
});

// Animate numbers
function animateNumber(element, start, end, duration, prefix = '', suffix = '') {
    const startTime = performance.now();
    
    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        const current = Math.floor(start + (end - start) * easeOutQuad(progress));
        element.textContent = prefix + current + suffix;
        
        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }
    
    requestAnimationFrame(update);
}

// Easing function
function easeOutQuad(t) {
    return t * (2 - t);
}

// Scroll to next section
function scrollToNextSection() {
    const sections = Array.from(document.querySelectorAll('section[id]'));
    const currentScroll = window.pageYOffset;
    
    for (let section of sections) {
        if (section.offsetTop > currentScroll + 100) {
            section.scrollIntoView({ behavior: 'smooth' });
            break;
        }
    }
}

// Scroll to previous section
function scrollToPreviousSection() {
    const sections = Array.from(document.querySelectorAll('section[id]')).reverse();
    const currentScroll = window.pageYOffset;
    
    for (let section of sections) {
        if (section.offsetTop < currentScroll - 100) {
            section.scrollIntoView({ behavior: 'smooth' });
            break;
        }
    }
}

// Add tooltips
function addTooltips() {
    const tooltipElements = document.querySelectorAll('[data-tooltip]');
    
    tooltipElements.forEach(element => {
        element.addEventListener('mouseenter', function(e) {
            const tooltip = document.createElement('div');
            tooltip.className = 'tooltip';
            tooltip.textContent = this.getAttribute('data-tooltip');
            tooltip.style.position = 'absolute';
            tooltip.style.background = 'rgba(0,0,0,0.9)';
            tooltip.style.color = 'white';
            tooltip.style.padding = '0.5rem 1rem';
            tooltip.style.borderRadius = '5px';
            tooltip.style.fontSize = '0.9rem';
            tooltip.style.zIndex = '10000';
            tooltip.style.pointerEvents = 'none';
            
            document.body.appendChild(tooltip);
            
            const rect = this.getBoundingClientRect();
            tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px';
            tooltip.style.top = rect.top - tooltip.offsetHeight - 10 + window.scrollY + 'px';
            
            this._tooltip = tooltip;
        });
        
        element.addEventListener('mouseleave', function() {
            if (this._tooltip) {
                this._tooltip.remove();
                this._tooltip = null;
            }
        });
    });
}

// Animate cost comparison
function animateCostComparison() {
    const costCards = document.querySelectorAll('.cost-card');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'scale(1)';
                }, index * 200);
            }
        });
    }, { threshold: 0.5 });

    costCards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'scale(0.9)';
        card.style.transition = 'opacity 0.5s ease-out, transform 0.5s ease-out';
        observer.observe(card);
    });
}

// Add parallax effect to hero section
window.addEventListener('scroll', () => {
    const hero = document.querySelector('.hero');
    if (hero) {
        const scrolled = window.pageYOffset;
        hero.style.transform = `translateY(${scrolled * 0.5}px)`;
    }
});

// Add click to copy functionality for technical specs
document.addEventListener('DOMContentLoaded', () => {
    const infoValues = document.querySelectorAll('.info-value');
    
    infoValues.forEach(value => {
        value.style.cursor = 'pointer';
        value.title = 'Click to copy';
        
        value.addEventListener('click', function() {
            const text = this.textContent;
            navigator.clipboard.writeText(text).then(() => {
                const originalText = this.textContent;
                this.textContent = '✓ Copied!';
                this.style.color = 'var(--success-color)';
                
                setTimeout(() => {
                    this.textContent = originalText;
                    this.style.color = '';
                }, 1500);
            });
        });
    });
});

// Add print functionality
function printShowcase() {
    window.print();
}

// Add export to PDF functionality (requires html2pdf library)
function exportToPDF() {
    alert('PDF export functionality would require html2pdf.js library. This is a placeholder.');
}

// Console easter egg
console.log('%c🔒 Air-Gapped Jenkins Infrastructure', 'font-size: 20px; font-weight: bold; color: #2563eb;');
console.log('%cProject Status: ✅ Production Ready', 'font-size: 14px; color: #10b981;');
console.log('%cMonthly Cost: $84.30 | Annual Savings: $768', 'font-size: 14px; color: #f59e0b;');
console.log('%cDeployment Time: ~20 minutes', 'font-size: 14px;');
console.log('%c\nFor more information, check out PROJECT-OVERVIEW.md', 'font-size: 12px; font-style: italic;');
