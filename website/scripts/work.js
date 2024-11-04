let githubDataFetched = false;

function createWorkExperienceBox(workExperience) {
  const box = document.createElement('div');
  box.className = 'box work-box';
  box.innerHTML = `
    <h3>${workExperience.title}</h3>
    <p class= "years">${workExperience.years}</p>
    <p>${workExperience.description}</p>
  `;

  return box;
}

function createGitHubRepoBox(githubRepo) {
  const box = document.createElement('div');
  box.className = 'box github-box';
  box.innerHTML = `
    <h3><a href="${githubRepo.html_url}">${githubRepo.name}</a></h3>
    <p>${githubRepo.description || 'No description available'}</p>
    <div class="repo-stats">
    </div>
  `;
  return box;
}

function createGitHubProfileSection(userData) {
  const profileSection = document.createElement('div');
  profileSection.className = 'github-profile';
  profileSection.innerHTML = `
    <img src="${userData.avatar_url}" alt="GitHub Profile Picture" class="profile-picture">
    <h3>${userData.name}</h3>
    <p>${userData.bio}</p>
    <p>Followers: ${userData.followers} | Following: ${userData.following}</p>
    <a href="${userData.html_url}" target="_blank" rel="noopener noreferrer">View GitHub Profile</a>
    <div class="github-stats">
      <div class="stats-container">
        <img src="https://github-readme-stats.vercel.app/api?username=${userData.login}&show_icons=true&theme=radical" alt="GitHub Stats">
      </div>
      <div class="stats-container">
        <img src="https://github-readme-streak-stats.herokuapp.com/?user=${userData.login}&theme=radical" alt="GitHub Streak">
      </div>
    </div>
    <div class="stats-container trophies">
      <img src="https://github-profile-trophy.vercel.app/?username=${userData.login}&theme=radical&column=4" alt="GitHub Trophies">
    </div>
  `;
  return profileSection;
}

function fetchGitHubData() {
  if (githubDataFetched) {
    console.log('GitHub data already fetched. Skipping...');
    return;
  }

  const githubProfileContainer = document.getElementById('github-profile');
  const githubReposContainer = document.getElementById('github-repos-container');

  if (!githubProfileContainer || !githubReposContainer) {
    console.error('GitHub containers not found');
    return;
  }

  // Clear existing content to prevent duplication
  githubProfileContainer.innerHTML = '';
  githubReposContainer.innerHTML = '';

  Promise.all([
    fetch('https://api.github.com/users/tatosf').then(res => res.json()),
    fetch('https://api.github.com/users/tatosf/repos?sort=created&direction=desc&per_page=6').then(res => res.json())
  ])
    .then(([userData, reposData]) => {
      githubProfileContainer.appendChild(createGitHubProfileSection(userData));

      const fragment = document.createDocumentFragment();
      reposData.forEach(repo => {
        const box = createGitHubRepoBox(repo);
        fragment.appendChild(box);
      });
      githubReposContainer.appendChild(fragment);

      githubDataFetched = true;
    })
    .catch(error => {
      console.error('Error fetching GitHub data:', error);
    });
}

function initializePage() {
  const workExperienceContainer = document.getElementById('work-experience-container');
  if (workExperienceContainer) {
    const workExperienceItems = [
      {
        title: 'Proycon - Tech Intern',
        years: 'May - August 2021',
        description: "Shadowed the Technology Manager in the company in his day-to-day. Improved the organization of bought hardware, improving excel sheets for inventory being used. Helped with day to day tech problems"
      },
      {
        title: 'Economic Data Lab - OCP Notariado',
        years: 'May - July 2022',
        description: 'Predicting operations with high risk of money laundering, identifying relevant features based on big data.',
      },
      {
        title: 'MUSCLE Points - Software Engineer Intern',
        years: 'June - August 2023',
        description: 'Helped create web application for KPI internal metrics for banking clients using React. Also used cypress to create tests for the website.',
      },
      {
        title: '41OPS - Data Engineer Intern',
        years: 'June - August 2024',
        description: 'Developed a KPI page for managers to monitor broker performance. Created a compliance module, allowing employees to add compliance documentation for AI models upon deployment.',
      },
    ];
    const fragment = document.createDocumentFragment();
    workExperienceItems.forEach(item => {
      const box = createWorkExperienceBox(item);
      fragment.appendChild(box);
    });
    workExperienceContainer.appendChild(fragment);
  } else {
    console.error('Work experience container not found');
  }

  fetchGitHubData();

  // Show the page content after initialization
  const pageBody = document.getElementById('page-body');
  if (pageBody) {
    pageBody.style.display = 'block';
  }
}

// Only call initializePage when the DOM is fully loaded
document.addEventListener('DOMContentLoaded', initializePage);